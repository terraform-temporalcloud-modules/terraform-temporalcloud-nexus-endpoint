# Reports test resources still present in the account.
#
# Creates nothing: two data sources and outputs only. `terraform test` destroys
# what it creates, but a cancelled or crashed run can leave resources behind, and
# nothing else would notice.
#
# Both kinds are checked. The endpoint is what this module manages, but the suite
# also creates the namespaces the endpoint routes between, and those are the more
# expensive thing to leak.
#
# Run after the apply tests. Anything reported here is a leftover.

data "temporalcloud_nexus_endpoints" "all" {}

data "temporalcloud_namespaces" "all" {}

locals {
  # Labels carry no spaces: the reporting script splits the JSON list on
  # whitespace, so "nexus-endpoint:name" stays one entry where "endpoint name"
  # would become two.
  orphan_endpoints = [
    for e in data.temporalcloud_nexus_endpoints.all.nexus_endpoints : "nexus-endpoint:${e.name}"
    if startswith(e.name, var.test_resource_prefix)
  ]

  orphan_namespaces = [
    for n in data.temporalcloud_namespaces.all.namespaces : "namespace:${n.name}"
    if startswith(n.name, var.test_resource_prefix)
  ]

  orphans = concat(local.orphan_endpoints, local.orphan_namespaces)
}
