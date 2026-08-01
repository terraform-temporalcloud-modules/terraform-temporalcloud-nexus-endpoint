output "endpoint_name" {
  description = "Unique Nexus endpoint name for this test run, prefixed `yulei-tftest-nxs-` so leftovers from an interrupted run are identifiable in the Temporal Cloud account"
  # `yulei-` identifies the owner, `tftest-` distinguishes test resources from
  # anything created by hand. Satisfies the provider's constraint: starts with a
  # letter, letters, digits and hyphens only, no trailing hyphen.
  value = "yulei-tftest-nxs-${random_pet.this.id}"
}

output "target_namespace_id" {
  description = "ID of the namespace the endpoint routes to, in the form `<namespace>.<account_id>`"
  value       = temporalcloud_namespace.target.id
}

output "caller_namespace_id" {
  description = "ID of a second namespace, used to prove a caller other than the target is accepted"
  value       = temporalcloud_namespace.caller.id
}

output "target_namespace_name" {
  description = "Name of the target namespace, so a test can assert the ID is not merely the bare name"
  value       = temporalcloud_namespace.target.name
}

output "region" {
  description = "The region the test namespaces were created in, reported so a failing run shows which of the account's entitlements was used"
  value       = local.region
}
