module "wrapper" {
  source = "../"

  for_each = var.items

  allowed_caller_namespaces = try(each.value.allowed_caller_namespaces, var.defaults.allowed_caller_namespaces, [])
  create_nexus_endpoint     = try(each.value.create_nexus_endpoint, var.defaults.create_nexus_endpoint, true)
  description               = try(each.value.description, var.defaults.description, null)
  name                      = try(each.value.name, var.defaults.name, "")
  timeouts                  = try(each.value.timeouts, var.defaults.timeouts, {})
  worker_target             = try(each.value.worker_target, var.defaults.worker_target, null)
}
