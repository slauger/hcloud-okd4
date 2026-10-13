# Node Pools

`node_pools` replaces the identical workers of `replicas_worker` with pools of differently configured nodes. Configure it in `terraform/node_pools.auto.tfvars`, which Terraform reads automatically and git ignores. Start from the commented example:

```bash
cp terraform/node_pools.auto.tfvars.example terraform/node_pools.auto.tfvars
```

Each pool is a map entry, the key is the pool name:

| Option | Required | Default | Description |
|---|---|---|---|
| `count` | yes | | Number of nodes |
| `ip_offset` | yes | | Host number of the first node in the node subnet (`192.168.254.0/24` by default). It has to be above the masters (`10 + replicas_master`), the ranges of the pools must not overlap. |
| `server_type` | no | `worker_server_type`, then `server_type` | Hetzner server type |
| `volumes` | no | `[]` | Sizes in GB of unformatted data volumes per node (10–10240 GB, at most 16), see [storage.md](storage.md) |
| `ingress` | no | `false` | Target of the public load balancer for ports 80/443 |
| `labels` | no | `{}` | Additional Kubernetes labels |
| `taints` | no | `[]` | Kubernetes taints, `{ key, value (optional), effect }` |

```hcl
node_pools = {
  infra = {
    count       = 3
    ip_offset   = 50
    server_type = "cpx32"
    ingress     = true
    taints      = [{ key = "node-role.kubernetes.io/infra", effect = "NoSchedule" }]
  }
  storage = {
    count     = 3
    ip_offset = 70
    volumes   = [500, 500]
    labels    = { "cluster.ocs.openshift.io/openshift-storage" = "" }
  }
  app = { count = 2, ip_offset = 90 }
}
```

A `.auto.tfvars` file takes precedence over `TF_VAR_*` environment variables. `TF_VAR_node_pools` works as well, but is hard to read for more than one pool.

## Addresses and names

The nodes are named `<pool><number>.<cluster domain>` and get the private addresses `ip_offset`, `ip_offset + 1`, ... of the node subnet. Names and addresses are fixed, so the DNS records can be created before the servers. Changing `ip_offset` of an existing pool replaces its servers. Pick the ranges with some room for growth, e.g. steps of 20 starting at 50.

Pool names may contain lowercase letters, digits and dashes and must not be `bootstrap` or `master`. Without `node_pools`, the worker variables form the pool `worker` with `ip_offset = 50` and `ingress = true`, so existing workers keep their names and addresses.

## Load balancer

The public load balancer targets the masters and the nodes of pools with `ingress = true`. Its health checks are per service: only nodes with a running API server receive API traffic, only nodes with a router receive ingress traffic. Pools without `ingress` are no targets at all.

## Roles, labels and taints

All pools join as workers (machine config pool `worker`). Kubernetes labels and taints are not part of the ignition config, `make label_nodes` applies them after the nodes joined:

- `node-role.kubernetes.io/<pool>` for every node
- the `labels` and `taints` of its pool

Nodes that have not joined yet are skipped, run it again once all nodes are Ready (e.g. after `make sign_csr`). It overwrites existing values, but does not remove labels or taints that were removed from a pool.

## Infra nodes

The default IngressController places the routers on worker nodes. To move them to an infra pool (which needs `ingress = true`) and tolerate its taint:

```bash
oc patch ingresscontroller/default -n openshift-ingress-operator --type merge -p '{
  "spec": {
    "replicas": 3,
    "nodePlacement": {
      "nodeSelector": { "matchLabels": { "node-role.kubernetes.io/infra": "" } },
      "tolerations": [{ "key": "node-role.kubernetes.io/infra", "operator": "Exists", "effect": "NoSchedule" }]
    }
  }
}'
```

The image registry (`configs.imageregistry.operator.openshift.io/cluster`, `spec.nodeSelector` and `spec.tolerations`) and the monitoring stack (`cluster-monitoring-config` ConfigMap in `openshift-monitoring`) are moved the same way, see the OpenShift documentation on infrastructure nodes.

The masters are schedulable as long as the cluster is installed without compute replicas, which is the case here. To keep workloads off the masters once worker pools exist:

```bash
oc patch schedulers.config.openshift.io cluster --type merge -p '{"spec":{"mastersSchedulable":false}}'
```

See the [README](../README.md) for the overall architecture and the deployment steps.
