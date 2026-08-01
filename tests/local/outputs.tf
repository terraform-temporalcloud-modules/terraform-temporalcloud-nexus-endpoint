# Referencing every output forces Terraform to evaluate each one, so a broken
# output expression fails validation here rather than in a consumer's plan.
#
# `nexus_endpoint_description` is kept out of the aggregates and given its own
# output: it is sensitive, and including it would force the whole aggregate to be
# marked sensitive, hiding everything else.

output "all_inputs" {
  description = "Every non-sensitive output of the fully configured module instance"
  value = {
    nexus_endpoint_id                        = module.all_inputs.nexus_endpoint_id
    nexus_endpoint_name                      = module.all_inputs.nexus_endpoint_name
    nexus_endpoint_worker_target             = module.all_inputs.nexus_endpoint_worker_target
    nexus_endpoint_target_namespace_id       = module.all_inputs.nexus_endpoint_target_namespace_id
    nexus_endpoint_target_task_queue         = module.all_inputs.nexus_endpoint_target_task_queue
    nexus_endpoint_allowed_caller_namespaces = module.all_inputs.nexus_endpoint_allowed_caller_namespaces
  }
}

output "all_inputs_description" {
  description = "The sensitive description output of the fully configured module instance"
  value       = module.all_inputs.nexus_endpoint_description
  sensitive   = true
}

output "disabled" {
  description = "Outputs when create_nexus_endpoint is false — every one must fall back rather than error"
  value = {
    nexus_endpoint_id                        = module.disabled.nexus_endpoint_id
    nexus_endpoint_name                      = module.disabled.nexus_endpoint_name
    nexus_endpoint_worker_target             = module.disabled.nexus_endpoint_worker_target
    nexus_endpoint_target_namespace_id       = module.disabled.nexus_endpoint_target_namespace_id
    nexus_endpoint_target_task_queue         = module.disabled.nexus_endpoint_target_task_queue
    nexus_endpoint_allowed_caller_namespaces = module.disabled.nexus_endpoint_allowed_caller_namespaces
  }
}

output "disabled_description" {
  description = "The sensitive description output with the module switched off, which must fall back to an empty string"
  value       = module.disabled.nexus_endpoint_description
  sensitive   = true
}

output "minimal" {
  description = "Outputs from the minimum viable module call"
  value       = module.minimal.nexus_endpoint_id
}

output "wrapper" {
  description = "Wrapper outputs, keyed by item name"
  value       = module.wrapper.wrapper
  sensitive   = true
}
