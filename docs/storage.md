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

The volumes are named `<node>-data<n>` and are attached to their node by a separate resource. When a node is rebuilt, e.g. with `terraform apply -replace='module.pool["storage"].hcloud_server.server[1]'`, the volumes keep their data and are attached to the new server, which has the same name. Rook-Ceph and LVM Storage find their existing data there. Reducing the `count` of a pool or removing volumes from the list deletes the volumes of the removed nodes or positions.

Inside the node the volumes show up as `/dev/sdb`, `/dev/sdc`, ... in the order they were attached, with a stable path below `/dev/disk/by-id/scsi-0HC_Volume_<volume id>`. The Terraform output `data_volumes` lists the stable paths per node. With a single volume per node, `/dev/sdb` is fine. With several volumes, use the by-id paths, the order of the `sdX` names is not guaranteed after a reattach. Example for an `LVMCluster`:

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

For Rook-Ceph, set `useAllDevices: false` and select the volumes with `deviceFilter: ^sd[b-z]$`, or list the by-id paths per node from `data_volumes` under `storage.nodes`. Restrict the OSDs to a storage pool with a node affinity on `node-role.kubernetes.io/storage` in `placement`. Hetzner Volumes are network attached, Ceph based block storage. They have higher latency and lower IOPS than the local NVMe disks of the servers, and Rook-Ceph on top of them replicates the data twice. This is fine for functional tests, but does not reflect the performance of local disks.

See the [README](../README.md) for the overall architecture and the deployment steps.
