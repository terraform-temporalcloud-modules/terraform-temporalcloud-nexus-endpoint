// Verifies create_nexus_endpoint = false against a real provider.
//
// Separate file so it gets its own state and cannot interfere with the endpoint
// created in nexus_endpoint.tftest.hcl. Creates no resources, and needs no
// namespaces, so it is the one cheap file in this suite — but it still configures
// the provider, which is why it needs TEMPORAL_CLOUD_API_KEY.

provider "temporalcloud" {}

run "creates_nothing" {
  variables {
    create_nexus_endpoint = false
  }

  // Every output is count-gated behind try(); these assertions prove the
  // fallbacks evaluate rather than erroring when the module is switched off.
  // They also prove the worker_target validations tolerate a null object, which
  // is only valid in this state.
  assert {
    condition     = output.nexus_endpoint_id == ""
    error_message = "nexus_endpoint_id should fall back to empty when create_nexus_endpoint = false"
  }

  assert {
    condition     = output.nexus_endpoint_name == ""
    error_message = "nexus_endpoint_name should fall back to empty when create_nexus_endpoint = false"
  }

  assert {
    condition     = output.nexus_endpoint_target_namespace_id == ""
    error_message = "nexus_endpoint_target_namespace_id should fall back to empty"
  }

  assert {
    condition     = output.nexus_endpoint_target_task_queue == ""
    error_message = "nexus_endpoint_target_task_queue should fall back to empty"
  }

  assert {
    // length(), not == {}: the output is an empty object, which never compares
    // equal to a map.
    condition     = length(output.nexus_endpoint_worker_target) == 0
    error_message = "nexus_endpoint_worker_target should fall back to an empty object"
  }

  assert {
    condition     = length(output.nexus_endpoint_allowed_caller_namespaces) == 0
    error_message = "nexus_endpoint_allowed_caller_namespaces should fall back to an empty list"
  }

  // nonsensitive() is required: the output is declared sensitive because the
  // provider marks the underlying attribute sensitive.
  assert {
    condition     = nonsensitive(output.nexus_endpoint_description) == ""
    error_message = "nexus_endpoint_description should fall back to empty"
  }
}
