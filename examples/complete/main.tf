provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

locals {
  name = "ex-${basename(path.cwd)}"

  tags = {
    example   = local.name
    terraform = "true"
  }
}

################################################################################
# Namespaces
#
# Two namespaces stand in for two teams:
#
#   payments — owns the Nexus service, and runs the workers that serve it
#   web      — calls the service from its own workflows
#
# They exist here so the example runs end to end. In a real configuration these
# are usually managed elsewhere, and only their `namespace_id` outputs are passed
# in — see the `single-caller` example for that shape.
################################################################################

module "payments_namespace" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud"
  version = "~> 1.0"

  name           = "${local.name}-payments"
  regions        = ["aws-us-east-1"]
  retention_days = 7
  api_key_auth   = true

  tags = local.tags
}

module "web_namespace" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud"
  version = "~> 1.0"

  name           = "${local.name}-web"
  regions        = ["aws-us-east-1"]
  retention_days = 7
  api_key_auth   = true

  tags = local.tags
}

################################################################################
# Nexus endpoint
#
# Every namespace reference below is a namespace ID (`<namespace>.<account_id>`),
# taken from the namespace module's `namespace_id` output rather than typed out.
# Passing a bare namespace name is the most common way to get this wrong.
################################################################################

module "nexus_endpoint" {
  source  = "terraform-temporalcloud-modules/nexus-endpoint/temporalcloud"
  version = "~> 1.0"

  name        = local.name
  description = "Payment authorisation and capture, served by the payments team"

  # Requests to this endpoint are routed to workers in the payments namespace
  # polling the `payments-nexus` task queue. Nothing serves the endpoint until
  # such a worker is running — the endpoint is routing configuration only.
  worker_target = {
    namespace_id = module.payments_namespace.namespace_id
    task_queue   = "payments-nexus"
  }

  # Callers not listed here are rejected. The target namespace is included
  # deliberately: a namespace calling its own endpoint is not implicitly allowed.
  allowed_caller_namespaces = [
    module.web_namespace.namespace_id,
    module.payments_namespace.namespace_id,
  ]

  timeouts = {
    create = "10m"
    delete = "10m"
  }
}
