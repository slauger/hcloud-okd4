# Additional Disks (LVM Storage / Ceph)

Every master and worker node can get an additional, unformatted Hetzner Volume, e.g. for the LVM Storage operator or Rook-Ceph. Volumes can also be added to a running cluster:

```bash
export TF_VAR_worker_volume_size=100 # GB per worker, 0 (default) = no volume
export TF_VAR_master_volume_size=100 # GB per master, only useful if masters run workloads
make infrastructure
```

Inside the node the volume shows up as `/dev/sdb`, with a stable path below `/dev/disk/by-id/scsi-0HC_Volume_<volume id>`. The by-id path differs per node, so the examples use `/dev/sdb`, which is stable as long as each node has only this one volume attached. Example for an `LVMCluster`:

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

For Rook-Ceph, set `useAllDevices: false` and select the volume with `deviceFilter: ^sdb$`. Hetzner Volumes are network attached block storage, which is fine for test clusters but not for performance testing.

See the [README](../README.md) for the overall architecture and the deployment steps.
