# Additional Disks (LVM Storage / Ceph)

Masters and the nodes of a pool can get additional, unformatted Hetzner Volumes, e.g. for the LVM Storage operator or Rook-Ceph. Volumes can also be added to a running cluster:

```hcl
# terraform/node_pools.auto.tfvars, see docs/node-pools.md
node_pools = {
  storage = { count = 3, ip_offset = 70, volumes = [500, 500] } # two volumes per node
}
master_volumes = [100] # GB per volume and master, only useful if masters run workloads
```

```bash
make infrastructure
```

Without `node_pools`, `TF_VAR_worker_volume_size` adds one volume per worker (and `TF_VAR_master_volume_size` one per master).

The volumes are named `<node>-data<n>` and are attached to their node by a separate resource. When a node is rebuilt, e.g. with `terraform apply -replace='module.pool["storage"].hcloud_server.server[1]'`, the volumes keep their data and are attached to the new server, which has the same name. The new node joins with a new kubelet, so approve its CSRs (`make sign_csr`, twice). Its labels and taints are kept as long as the node object was not deleted, otherwise run `make label_nodes` again. Rook-Ceph and LVM Storage find their existing data there. Reducing the `count` of a pool deletes the volumes of the removed nodes. Volumes are identified by their position in the list, so only append new sizes: removing an entry deletes the volume at the last position and shifts the sizes of the following ones, and Hetzner Volumes can only grow, not shrink.

Volumes created by `worker_volume_size` or `master_volume_size` before the introduction of node pools are attached differently and are replaced by new, empty volumes on the next `make infrastructure`.

Inside the node the volumes show up as `/dev/sdb`, `/dev/sdc`, ..., with a stable path below `/dev/disk/by-id/scsi-0HC_Volume_<volume id>`. The volumes are attached in parallel, so with several volumes the order of the `sdX` names is not guaranteed. The Terraform output `data_volumes` lists the by-id paths per node, but they differ from node to node. LVM identifies its physical volumes by their metadata, so listing all `sdX` devices of the data volumes works regardless of their order. Example for an `LVMCluster` with one volume per node (add `/dev/sdc`, ... for more):

```yaml
spec:
  storage:
    deviceClasses:
      - name: vg1
        deviceSelector:
          paths:
            - /dev/sdb
        thinPoolConfig:
          name: thin-pool-1
          sizePercent: 90
          overprovisionRatio: 10
```

For Rook-Ceph, set `useAllDevices: false` and select the volumes with `deviceFilter: ^sd[b-z]$`, or list the by-id paths per node from `data_volumes` under `storage.nodes`. Restrict the OSDs to a storage pool with a node affinity on `node-role.kubernetes.io/storage` in `placement`. Hetzner Volumes are network attached, Ceph based block storage. They have higher latency and lower IOPS than the local NVMe disks of the servers, and Rook-Ceph replicates the data again on top of them (3 copies by default). This is fine for functional tests, but does not reflect the performance of local disks.

See the [README](../README.md) for the overall architecture and the deployment steps.
