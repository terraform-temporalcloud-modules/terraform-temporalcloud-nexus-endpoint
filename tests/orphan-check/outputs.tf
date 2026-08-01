output "orphans" {
  description = "Test Nexus endpoints and namespaces still present in the account, each labelled with its kind"
  value       = local.orphans
}

output "orphan_count" {
  description = "Number of test resources still present"
  value       = length(local.orphans)
}
