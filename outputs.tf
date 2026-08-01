################################################################################
# Nexus endpoint
#
# Outputs are wrapped in `try()` so they still evaluate to an empty value when
# `create_nexus_endpoint = false` leaves no resource to reference.
################################################################################

output "nexus_endpoint_id" {
  description = "The unique identifier of the Nexus endpoint"
  value       = try(temporalcloud_nexus_endpoint.this[0].id, "")
}

output "nexus_endpoint_name" {
  description = "The name of the Nexus endpoint. This is the name callers address in `NexusClient` / `nexus_service` configuration"
  value       = try(temporalcloud_nexus_endpoint.this[0].name, "")
}

output "nexus_endpoint_description" {
  description = "The description of the Nexus endpoint. Marked sensitive because the provider marks the underlying attribute sensitive; read it with `terraform output -raw` or `nonsensitive()`"
  value       = try(temporalcloud_nexus_endpoint.this[0].description, "")
  sensitive   = true
}

################################################################################
# Routing
#
# The target is exposed both as a whole and field by field, since wiring a worker
# usually needs the task queue on its own.
################################################################################

output "nexus_endpoint_worker_target" {
  description = "The endpoint's routing target, as an object of `namespace_id` and `task_queue`"
  value       = try(temporalcloud_nexus_endpoint.this[0].worker_target, {})
}

output "nexus_endpoint_target_namespace_id" {
  description = "The ID of the namespace whose workers serve requests to this endpoint, in the form `<namespace>.<account_id>`"
  value       = try(temporalcloud_nexus_endpoint.this[0].worker_target.namespace_id, "")
}

output "nexus_endpoint_target_task_queue" {
  description = "The task queue the target namespace's Nexus workers must poll to serve this endpoint"
  value       = try(temporalcloud_nexus_endpoint.this[0].worker_target.task_queue, "")
}

output "nexus_endpoint_allowed_caller_namespaces" {
  description = "The IDs of the namespaces permitted to call this endpoint"
  value       = try(temporalcloud_nexus_endpoint.this[0].allowed_caller_namespaces, [])
}
