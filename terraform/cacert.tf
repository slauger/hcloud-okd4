data "local_file" "ignition_master_file" {
  filename = "${path.root}/../ignition/master.ign"
}

data "local_file" "ignition_worker_file" {
  filename = "${path.root}/../ignition/worker.ign"
}

locals {
  ignition_master_cacert = jsondecode(data.local_file.ignition_master_file.content).ignition.security.tls.certificateAuthorities[0].source
  ignition_worker_cacert = jsondecode(data.local_file.ignition_worker_file.content).ignition.security.tls.certificateAuthorities[0].source
}

#resource "local_file" "ignition_cacert" {
#  content  = local.ignition_cacert
#  filename = "${path.root}/ignition_ca.crt"
#}
