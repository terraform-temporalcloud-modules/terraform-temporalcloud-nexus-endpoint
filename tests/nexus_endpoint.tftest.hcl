// Main lifecycle: create one Nexus endpoint routing between two real namespaces,
// then update it in place.
//
// Creates ONE endpoint and updates it across run blocks rather than one per case.
// Run blocks share state within a file, so a later block with different variables
// updates the endpoint instead of creating another.
//
// The wrapper is exercised in this file too, rather than in one of its own, so it
// can reuse `run.setup`. A separate file would create a second pair of namespaces,
// and namespace creation is what makes this suite slow.
//
// terraform test destroys everything it created when the file finishes, including
// after a failed assertion.

provider "temporalcloud" {
  // Reads TEMPORAL_CLOUD_API_KEY from the environment. The module under test
  // declares no provider block, by design for a published module, so the test
  // supplies one.
}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "create_endpoint" {
  variables {
    name        = run.setup.endpoint_name
    description = "Created by the apply tests"

    worker_target = {
      namespace_id = run.setup.target_namespace_id
      task_queue   = "payments-nexus"
    }

    allowed_caller_namespaces = [run.setup.caller_namespace_id]

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  assert {
    condition     = output.nexus_endpoint_id != ""
    error_message = "the endpoint was not created"
  }

  assert {
    condition     = output.nexus_endpoint_name == run.setup.endpoint_name
    error_message = "nexus_endpoint_name output did not echo the requested name"
  }

  // The routing target must come back as the namespace ID, not the bare namespace
  // name. This is the mistake consumers make most often, so it is asserted both
  // ways round.
  assert {
    condition     = output.nexus_endpoint_target_namespace_id == run.setup.target_namespace_id
    error_message = "worker_target.namespace_id did not round-trip through the API"
  }

  assert {
    condition     = output.nexus_endpoint_target_namespace_id != run.setup.target_namespace_name
    error_message = "the target namespace ID matched the bare namespace name; the `<namespace>.<account_id>` assumption no longer holds"
  }

  assert {
    condition     = output.nexus_endpoint_target_task_queue == "payments-nexus"
    error_message = "worker_target.task_queue did not round-trip through the API"
  }

  // The composite output, so a break in it fails here rather than in a
  // consumer's configuration.
  assert {
    condition     = output.nexus_endpoint_worker_target.task_queue == "payments-nexus"
    error_message = "nexus_endpoint_worker_target did not expose the task queue"
  }

  assert {
    // length() and contains(), not ==: the output comes from try(..., []) so it
    // is a tuple, which never compares equal to a list.
    condition     = length(output.nexus_endpoint_allowed_caller_namespaces) == 1
    error_message = "expected exactly one allowed caller namespace"
  }

  assert {
    condition     = contains(output.nexus_endpoint_allowed_caller_namespaces, run.setup.caller_namespace_id)
    error_message = "the caller namespace is not in allowed_caller_namespaces"
  }

  // nonsensitive() is required: the provider marks `description` sensitive, so
  // the module output is sensitive too.
  assert {
    condition     = nonsensitive(output.nexus_endpoint_description) == "Created by the apply tests"
    error_message = "description did not round-trip through the API"
  }
}

// Updates the SAME endpoint: a second caller, a different task queue and a new
// description.
run "update_endpoint" {
  variables {
    name        = run.setup.endpoint_name
    description = "Updated by the apply tests"

    worker_target = {
      namespace_id = run.setup.target_namespace_id
      task_queue   = "payments-nexus-v2"
    }

    // The target namespace added as a caller of its own endpoint. Temporal Cloud
    // does not imply this, so it has to be listed explicitly.
    allowed_caller_namespaces = [
      run.setup.caller_namespace_id,
      run.setup.target_namespace_id,
    ]

    timeouts = {
      create = "10m"
      delete = "10m"
    }
  }

  // The endpoint must have been updated, not replaced.
  assert {
    condition     = output.nexus_endpoint_id == run.create_endpoint.nexus_endpoint_id
    error_message = "the endpoint was replaced rather than updated in place"
  }

  assert {
    condition     = length(output.nexus_endpoint_allowed_caller_namespaces) == 2
    error_message = "expected two allowed caller namespaces after the update"
  }

  assert {
    condition     = contains(output.nexus_endpoint_allowed_caller_namespaces, run.setup.target_namespace_id)
    error_message = "a namespace was not accepted as a caller of its own endpoint"
  }

  assert {
    condition     = output.nexus_endpoint_target_task_queue == "payments-nexus-v2"
    error_message = "the task queue was not updated"
  }

  assert {
    condition     = nonsensitive(output.nexus_endpoint_description) == "Updated by the apply tests"
    error_message = "the description was not updated"
  }
}

// The wrappers submodule: several endpoints from one call, with per-item overrides
// of the shared defaults. Last in the file so a failure here cannot make the
// lifecycle coverage above skip.
run "create_many" {
  module {
    source = "./wrappers"
  }

  variables {
    defaults = {
      allowed_caller_namespaces = [run.setup.caller_namespace_id]
    }

    items = {
      orders = {
        name = "${run.setup.endpoint_name}-orders"

        worker_target = {
          namespace_id = run.setup.target_namespace_id
          task_queue   = "orders-nexus"
        }
      }

      shipping = {
        name = "${run.setup.endpoint_name}-shipping"

        worker_target = {
          namespace_id = run.setup.target_namespace_id
          task_queue   = "shipping-nexus"
        }

        // Overrides the shared default above.
        allowed_caller_namespaces = [run.setup.target_namespace_id]
      }
    }
  }

  assert {
    condition     = length(output.wrapper) == 2
    error_message = "expected 2 endpoints from the wrapper, got ${length(output.wrapper)}"
  }

  assert {
    condition     = output.wrapper["orders"].nexus_endpoint_name == "${run.setup.endpoint_name}-orders"
    error_message = "the orders item did not take its own name"
  }

  // Shared defaults reach every item.
  assert {
    condition     = contains(output.wrapper["orders"].nexus_endpoint_allowed_caller_namespaces, run.setup.caller_namespace_id)
    error_message = "defaults.allowed_caller_namespaces did not reach the orders item"
  }

  // Per-item values override the defaults rather than merging with them.
  assert {
    condition     = length(output.wrapper["shipping"].nexus_endpoint_allowed_caller_namespaces) == 1
    error_message = "the shipping item merged the defaults instead of overriding them"
  }

  assert {
    condition     = output.wrapper["shipping"].nexus_endpoint_target_task_queue == "shipping-nexus"
    error_message = "per-item worker_target did not reach the shipping item"
  }
}
