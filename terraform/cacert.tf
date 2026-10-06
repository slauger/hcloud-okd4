# The ignition configs are only needed to create nodes, a missing file must not
# break terraform destroy. Creating nodes without the CA fails in the module.
locals {
  ignition_master_file = "${path.root}/../ignition/master.ign"
  ignition_worker_file = "${path.root}/../ignition/worker.ign"

  ignition_master_cacert = fileexists(local.ignition_master_file) ? jsondecode(file(local.ignition_master_file)).ignition.security.tls.certificateAuthorities[0].source : ""
  ignition_worker_cacert = fileexists(local.ignition_worker_file) ? jsondecode(file(local.ignition_worker_file)).ignition.security.tls.certificateAuthorities[0].source : ""
}
