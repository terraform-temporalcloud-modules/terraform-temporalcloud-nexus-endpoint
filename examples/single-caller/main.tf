provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

locals {
  name = "ex-${basename(path.cwd)}"
}

################################################################################
# Minimal Nexus endpoint against namespaces that already exist
#
# The smallest useful configuration: one caller, one target, no description.
#
# Namespaces are referenced by ID rather than created here, which is the common
# case once a platform team owns them. `data.temporalcloud_namespace` looks each
# one up so the configuration fails at plan if an ID is wrong, instead of at apply
# with an API error. Where the namespaces are managed by Terraform in the same
# configuration, pass the namespace module's `namespace_id` output straight in
# instead — see the `complete` example.
################################################################################

data "temporalcloud_namespace" "target" {
  id = var.target_namespace_id
}

data "temporalcloud_namespace" "caller" {
  id = var.caller_namespace_id
}

module "nexus_endpoint" {
  source  = "terraform-temporalcloud-modules/nexus-endpoint/temporalcloud"
  version = "~> 2.0"

  name = local.name

  worker_target = {
    namespace_id = data.temporalcloud_namespace.target.id
    task_queue   = "greetings-nexus"
  }

  allowed_caller_namespaces = [data.temporalcloud_namespace.caller.id]
}
