provider "temporalcloud" {
  # Reads TEMPORAL_CLOUD_API_KEY from the environment.
}

################################################################################
# Local regression coverage
#
# The examples/ directories source the PUBLISHED module so they are copy-pasteable
# for consumers. That means they validate the last release, not the code in this
# repo — a renamed or removed variable would slip through CI unnoticed.
#
# This directory closes that gap: it sources the module by relative path and
# passes EVERY input, so `terraform validate` fails here the moment the variable
# surface changes incompatibly. CI picks it up automatically because it contains a
# versions.tf with required_version.
#
# When you add a variable to the root module, add it here in the same PR. Adding
# it to examples/ has to wait until the next release publishes it.
#
# The namespace IDs below are placeholders in the correct `<namespace>.<account_id>`
# shape. Nothing here is applied by CI, so they never have to exist.
################################################################################

# Every input the module accepts.
module "all_inputs" {
  source = "../../"

  create_nexus_endpoint = true

  name        = "yulei-tflocal-endpoint"
  description = "Local regression coverage for every module input"

  worker_target = {
    namespace_id = "yulei-tflocal-target.a1b2c"
    task_queue   = "tflocal-nexus"
  }

  allowed_caller_namespaces = [
    "yulei-tflocal-caller.a1b2c",
    "yulei-tflocal-target.a1b2c",
  ]

  timeouts = {
    create = "10m"
    delete = "10m"
  }
}

# The create flag off: proves the module produces no resources and that every
# output still evaluates via its try() fallback.
#
# The three provider-required inputs are still passed. Terraform requires them
# whatever `create_nexus_endpoint` says, so these placeholders are what a
# switched-off call has to look like.
module "disabled" {
  source = "../../"

  create_nexus_endpoint = false

  name = ""

  worker_target = {
    namespace_id = "unused.unused"
    task_queue   = "unused"
  }

  allowed_caller_namespaces = []
}

# Minimum viable call: only the inputs the resource actually requires.
module "minimal" {
  source = "../../"

  name = "yulei-tflocal-minimal"

  worker_target = {
    namespace_id = "yulei-tflocal-target.a1b2c"
    task_queue   = "tflocal-nexus"
  }

  allowed_caller_namespaces = ["yulei-tflocal-caller.a1b2c"]
}

# The wrapper, exercised through the local path as well.
module "wrapper" {
  source = "../../wrappers"

  defaults = {
    allowed_caller_namespaces = ["yulei-tflocal-caller.a1b2c"]
  }

  items = {
    payments = {
      name          = "yulei-tflocal-payments"
      worker_target = { namespace_id = "yulei-tflocal-payments.a1b2c", task_queue = "payments-nexus" }
    }
    shipping = {
      name          = "yulei-tflocal-shipping"
      description   = "Overrides the shared defaults above"
      worker_target = { namespace_id = "yulei-tflocal-shipping.a1b2c", task_queue = "shipping-nexus" }

      allowed_caller_namespaces = ["yulei-tflocal-web.a1b2c"]
    }
  }
}
