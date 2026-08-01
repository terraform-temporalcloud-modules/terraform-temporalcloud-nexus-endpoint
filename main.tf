locals {
  create_nexus_endpoint = var.create_nexus_endpoint
}

################################################################################
# Nexus endpoint
#
# `worker_target` is a nested attribute in the provider schema rather than a
# block, so it is assigned straight from its variable. `timeouts` is the only
# true block, hence the dynamic block below.
################################################################################

resource "temporalcloud_nexus_endpoint" "this" {
  count = local.create_nexus_endpoint ? 1 : 0

  name                      = var.name
  allowed_caller_namespaces = var.allowed_caller_namespaces
  worker_target             = var.worker_target
  description               = var.description

  dynamic "timeouts" {
    for_each = length([for v in var.timeouts : v if v != null]) > 0 ? [var.timeouts] : []

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}
