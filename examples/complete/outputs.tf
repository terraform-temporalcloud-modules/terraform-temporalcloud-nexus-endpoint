output "nexus_endpoint_id" {
  description = "The unique identifier of the Nexus endpoint"
  value       = module.nexus_endpoint.nexus_endpoint_id
}

output "nexus_endpoint_name" {
  description = "The endpoint name callers address when they create a Nexus client"
  value       = module.nexus_endpoint.nexus_endpoint_name
}

output "nexus_endpoint_target_namespace_id" {
  description = "The ID of the namespace whose workers serve this endpoint"
  value       = module.nexus_endpoint.nexus_endpoint_target_namespace_id
}

output "nexus_endpoint_target_task_queue" {
  description = "The task queue the payments workers must poll"
  value       = module.nexus_endpoint.nexus_endpoint_target_task_queue
}

output "nexus_endpoint_allowed_caller_namespaces" {
  description = "The namespace IDs permitted to call this endpoint"
  value       = module.nexus_endpoint.nexus_endpoint_allowed_caller_namespaces
}
