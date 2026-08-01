# Prerequisites for the apply tests.
#
# A Nexus endpoint is pure routing configuration between two namespaces, so it
# cannot be applied without real namespaces on both sides. This fixture creates
# them, which makes this suite slower than most in the family — namespace creation
# dominates the runtime. Two is the minimum that exercises the cross-namespace
# behaviour, so no more are created.

# Unique per run: Temporal Cloud namespace names and Nexus endpoint names are both
# unique within an account, so fixed names would make a second run — or a
# concurrent one — fail on a name already in use, and would collide with anything a
# human left behind after a failed run.
resource "random_pet" "this" {
  length    = 2
  separator = "-"
}

# Regions this account is entitled to use.
#
# Not hardcoded: the regions an account may use are a subset of the published
# list, so a fixed ID makes the suite account-specific and can fail with
# "is not a valid Temporal Cloud region".
data "temporalcloud_regions" "available" {}

locals {
  # Sorted so repeat runs pick the same region and results stay comparable.
  region = sort([for r in data.temporalcloud_regions.available.regions : r.id])[0]

  base_name = "yulei-tftest-nxs-${random_pet.this.id}"
}

# The namespace whose workers would serve the endpoint. Nothing polls the task
# queue during the tests; the endpoint is routing configuration and is created
# regardless.
resource "temporalcloud_namespace" "target" {
  name           = "${local.base_name}-target"
  regions        = [local.region]
  retention_days = 1
  api_key_auth   = true
}

# A second namespace, so `allowed_caller_namespaces` is exercised with a caller
# that is genuinely a different namespace from the target.
resource "temporalcloud_namespace" "caller" {
  name           = "${local.base_name}-caller"
  regions        = [local.region]
  retention_days = 1
  api_key_auth   = true
}
