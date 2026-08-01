output "wrapper" {
  description = "Map of module outputs, keyed by the same keys as `items`. Marked sensitive because it carries `nexus_endpoint_description`, which the provider marks sensitive; read an individual value with `nonsensitive(module.<name>.wrapper[\"<key>\"].nexus_endpoint_id)`"
  value       = module.wrapper
  # Required, not stylistic: this aggregates every per-item module output, one of
  # which is sensitive, and Terraform refuses a root output carrying sensitive
  # data unless it says so.
  sensitive = true
}
