output "nexus_endpoint_id" {
  description = "The unique identifier of the Nexus endpoint"
  value       = module.nexus_endpoint.nexus_endpoint_id
}

output "nexus_endpoint_name" {
  description = "The endpoint name the caller addresses when it creates a Nexus client"
  value       = module.nexus_endpoint.nexus_endpoint_name
}

output "nexus_endpoint_target_task_queue" {
  description = "The task queue the target namespace's workers must poll"
  value       = module.nexus_endpoint.nexus_endpoint_target_task_queue
}
