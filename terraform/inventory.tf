data "template_file" "ansible_inventory" {
    template = file("./templates/inventory.tpl")
    vars = {
        ignition_node      = module.ignition.server_names[0]
        bootstrap_node     = module.bootstrap.server_names[0]
        haproxy_nodes      = join("\n", module.haproxy.server_names)
        master_nodes       = join("\n", module.master.server_names)
        worker_nodes       = join("\n", module.worker.server_names)
    }
}

resource "local_file" "ansible_inventory" {
  content  = data.template_file.ansible_inventory.rendered
  filename = "../inventory.ini"
}
