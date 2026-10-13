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
| `volumes` | no | `[]` | Sizes in GB of unformatted data volumes per node (10–10240 GB, at most 16). Only append to the list, see [storage.md](storage.md) |
| `ingress` | no | `false` | Nodes may run the router: target of the public load balancer and labeled `<cluster domain>/ingress=true`, see [Router placement](#router-placement) |
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

The nodes are named `<pool><number>.<cluster domain>` and get the private addresses `ip_offset`, `ip_offset + 1`, ... of the node subnet. Names and addresses are fixed, so the DNS records can be created before the servers. Do not change `ip_offset` of an existing pool, the nodes write their network configuration only on the first boot. Pick the ranges with some room for growth, e.g. steps of 20 starting at 50.

The default node subnet `192.168.254.0/24` has room for about 240 nodes in pools. For more, choose a larger subnet before the installation:

```hcl
network_cidr   = "192.168.0.0/16"   # Hetzner network, default
subnet_cidr    = "192.168.252.0/22" # nodes, ip_offset counts from here
lb_subnet_cidr = "192.168.251.0/24" # load balancers, must not overlap with subnet_cidr
```

Both subnets have to be part of `network_cidr`, and `machineNetwork` in `install-config.yaml` has to match `subnet_cidr`. None of them may overlap with the `clusterNetwork` (default `10.128.0.0/14`), the `serviceNetwork` (`172.30.0.0/16`) or the internal ranges of OVN-Kubernetes (`100.64.0.0/16`, `100.88.0.0/16`). The subnets cannot be changed on an installed cluster.

Pool names start and end with a lowercase letter, may contain digits and dashes and must not be `bootstrap`, `master` or `control-plane`. Without `node_pools`, the worker variables form the pool `worker` with `ip_offset = 50` and `ingress = true`, so existing workers keep their names and addresses. When switching an existing cluster to `node_pools`, keep a pool `worker` with the same `count`, `ip_offset = 50`, `ingress = true` and `volumes = [<worker_volume_size>]` (if set), otherwise Terraform deletes the existing workers or their volumes.

## Load balancer

The public load balancer targets the masters and the nodes of pools with `ingress = true`. Its health checks are per service: only nodes with a running API server receive API traffic, only nodes with a router receive ingress traffic. Pools without `ingress` are no targets at all, so a router on one of their nodes is unreachable, see [Router placement](#router-placement).

## Roles, labels and taints

All pools join as workers (machine config pool `worker`). Kubernetes labels and taints are not part of the ignition config, `make label_nodes` applies them after the nodes joined:

- `node-role.kubernetes.io/<pool>` for every node
- `<cluster domain>/ingress=true` for the nodes of pools with `ingress = true`
- the `labels` and `taints` of its pool

Nodes that have not joined yet are skipped and the target fails, run it again once all nodes are Ready (e.g. after `make sign_csr`). It overwrites existing values, but does not remove labels or taints that were removed from a pool.

## Router placement

The default IngressController places the routers on any node with the worker role, and every pool node has it (the masters as well, as long as they are schedulable). During the installation the routers run on the masters, the pool nodes join later. As soon as a router is rescheduled, e.g. during an update, it can land on a pool without `ingress = true`, which is no target of the load balancer, and `*.apps` including the console becomes unreachable.

So whenever a pool has `ingress = false`, pin the routers to the ingress pools after `make label_nodes`. Add a toleration for every taint of the ingress pools, and set `replicas` to at most the number of ingress nodes:

```bash
oc patch ingresscontroller/default -n openshift-ingress-operator --type merge -p '{
  "spec": {
    "replicas": 3,
    "nodePlacement": {
      "nodeSelector": { "matchLabels": { "okd4.example.com/ingress": "true" } },
      "tolerations": [{ "key": "node-role.kubernetes.io/infra", "operator": "Exists", "effect": "NoSchedule" }]
    }
  }
}'
oc -n openshift-ingress get pods -o wide # the routers move to the ingress nodes
```

Replace `okd4.example.com` with the cluster domain.

## Infra nodes

Besides the router (see above), the image registry and the monitoring stack can be moved to an infra pool: `spec.nodeSelector` and `spec.tolerations` of `configs.imageregistry.operator.openshift.io/cluster` (on `platform: none` the registry is `Removed` until storage is configured for it) and the `cluster-monitoring-config` ConfigMap in `openshift-monitoring`. See the OpenShift documentation on infrastructure nodes.

The installer marks the masters as schedulable once, because the cluster is installed without compute replicas. They stay schedulable when worker pools join. To keep workloads off the masters:

```bash
oc patch schedulers.config.openshift.io cluster --type merge -p '{"spec":{"mastersSchedulable":false}}'
```

See the [README](../README.md) for the overall architecture and the deployment steps.
