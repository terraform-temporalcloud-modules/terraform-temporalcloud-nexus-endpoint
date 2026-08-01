// Variable validation, exercised through plan so nothing is created.
//
// Each run block passes a value the module should refuse and names the variable
// it expects to fail. A run block whose expected failure does not occur fails the
// suite, so these guard against a validation being weakened or dropped.
//
// Variable validation runs before the provider is configured, so these blocks
// never reach the Temporal Cloud API and never create an endpoint or a namespace.
// They still sit in this file rather than in `local/` because `expect_failures`
// exists only in `terraform test`.

provider "temporalcloud" {}

// Underscores are the common case: they are legal in a Temporal namespace name
// but not in a Nexus endpoint name.
run "rejects_underscore_in_name" {
  command = plan

  variables {
    name = "bad_name_underscore"

    worker_target = {
      namespace_id = "tfplan-target.a1b2c"
      task_queue   = "tfplan-nexus"
    }

    allowed_caller_namespaces = ["tfplan-caller.a1b2c"]
  }

  expect_failures = [
    var.name,
  ]
}

// The mistake consumers make most often: passing the namespace *name* where a
// namespace ID is required. Only `worker_target` is malformed here, so the other
// two validations on this variable cannot be what fails.
run "rejects_bare_namespace_name_as_target" {
  command = plan

  variables {
    name = "tfplan-endpoint"

    worker_target = {
      namespace_id = "tfplan-target"
      task_queue   = "tfplan-nexus"
    }

    allowed_caller_namespaces = ["tfplan-caller.a1b2c"]
  }

  expect_failures = [
    var.worker_target,
  ]
}

// `namespace_id` is well formed here, so the empty task queue is the only rule
// that can fire.
run "rejects_empty_task_queue" {
  command = plan

  variables {
    name = "tfplan-endpoint"

    worker_target = {
      namespace_id = "tfplan-target.a1b2c"
      task_queue   = ""
    }

    allowed_caller_namespaces = ["tfplan-caller.a1b2c"]
  }

  expect_failures = [
    var.worker_target,
  ]
}

run "rejects_bare_namespace_name_as_caller" {
  command = plan

  variables {
    name = "tfplan-endpoint"

    worker_target = {
      namespace_id = "tfplan-target.a1b2c"
      task_queue   = "tfplan-nexus"
    }

    allowed_caller_namespaces = ["tfplan-caller"]
  }

  expect_failures = [
    var.allowed_caller_namespaces,
  ]
}
