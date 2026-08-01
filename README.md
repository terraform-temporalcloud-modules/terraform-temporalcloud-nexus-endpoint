# Temporal Cloud Nexus Endpoint Terraform module

[![CI](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/actions/workflows/pre-commit.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/actions/workflows/pre-commit.yml?query=branch%3Amain)
[![Apply Tests](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint/actions/workflows/test.yml?query=branch%3Amain)

Terraform module which creates a [Temporal Cloud](https://temporal.io/cloud) Nexus endpoint — the
routing entry that lets workflows in one namespace call a service served by workers in another.

Both badges report the state of `main`. **CI** covers formatting, linting,
documentation and `terraform validate`, and runs on every pull request and again
after merge. **Apply Tests** creates and destroys real namespaces and endpoints
against a live Temporal Cloud account, weekly and on demand — the only check that
proves the API accepts what this module sends.

## Namespace IDs, not namespace names

**This is the one thing to get right.** An endpoint names namespaces on both sides — the callers that
may reach it, and the target whose workers serve it — and every one of them is a namespace **ID** in
the form `<namespace>.<account_id>`:

```text
payments-prod.a1b2c
└── namespace name  └── account ID
```

A bare namespace name (`payments-prod`) looks correct, type-checks, and is rejected. Read the ID from
whatever manages the namespace rather than typing it:

| Source | Expression |
| --- | --- |
| The [namespace module](https://registry.terraform.io/modules/terraform-temporalcloud-modules/namespace/temporalcloud) | `module.payments.namespace_id` |
| A `temporalcloud_namespace` resource | `temporalcloud_namespace.payments.id` |
| A namespace managed elsewhere | `data.temporalcloud_namespace.payments.id` |
| The Temporal Cloud UI | the namespace's **Namespace ID**, not its name |

This module validates the shape during plan, so a bare name fails before the API is contacted:

```text
Error: Invalid value for variable
worker_target.namespace_id must be a namespace ID in the form `<namespace>.<account_id>`, ...
```

## Requirements

The `temporalcloud` provider authenticates with an API key, read from the `TEMPORAL_CLOUD_API_KEY`
environment variable:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"
```

The provider authenticates when it initialises, so a key is needed even for a `terraform plan` that
would create nothing. Keep the key out of version control — an untracked `.env` file rather than a
committed `.tfvars`.

The target namespace and every caller namespace must already exist, and must all be in the **same
account** as the endpoint.

## Usage

### Wired to the namespace module

The shape to prefer: no namespace ID is written by hand, so it cannot be written wrongly.

```hcl
module "payments_namespace" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud"
  version = "~> 1.0"

  name           = "payments-prod"
  regions        = ["aws-us-east-1"]
  retention_days = 30
  api_key_auth   = true
}

module "web_namespace" {
  source  = "terraform-temporalcloud-modules/namespace/temporalcloud"
  version = "~> 1.0"

  name           = "web-prod"
  regions        = ["aws-us-east-1"]
  retention_days = 30
  api_key_auth   = true
}

module "payments_endpoint" {
  source  = "terraform-temporalcloud-modules/nexus-endpoint/temporalcloud"
  version = "~> 1.0"

  name        = "payments-prod"
  description = "Payment authorisation and capture"

  # Requests are routed to workers in the payments namespace polling this queue.
  worker_target = {
    namespace_id = module.payments_namespace.namespace_id
    task_queue   = "payments-nexus"
  }

  # Callers not listed here are rejected.
  allowed_caller_namespaces = [
    module.web_namespace.namespace_id,
  ]
}
```

### Namespaces managed elsewhere

When a platform team owns the namespaces, look each one up so a wrong ID fails at plan:

```hcl
data "temporalcloud_namespace" "payments" {
  id = "payments-prod.a1b2c"
}

data "temporalcloud_namespace" "web" {
  id = "web-prod.a1b2c"
}

module "payments_endpoint" {
  source  = "terraform-temporalcloud-modules/nexus-endpoint/temporalcloud"
  version = "~> 1.0"

  name = "payments-prod"

  worker_target = {
    namespace_id = data.temporalcloud_namespace.payments.id
    task_queue   = "payments-nexus"
  }

  allowed_caller_namespaces = [data.temporalcloud_namespace.web.id]
}
```

### A namespace calling its own endpoint

Self-calls are not implicit. A namespace that is both the target and a caller has to appear in
`allowed_caller_namespaces` like any other:

```hcl
module "payments_endpoint" {
  source  = "terraform-temporalcloud-modules/nexus-endpoint/temporalcloud"
  version = "~> 1.0"

  name = "payments-prod"

  worker_target = {
    namespace_id = module.payments_namespace.namespace_id
    task_queue   = "payments-nexus"
  }

  allowed_caller_namespaces = [
    module.web_namespace.namespace_id,
    module.payments_namespace.namespace_id, # required for the target to call itself
  ]
}
```

## Notes

Provider and Temporal Cloud behaviours worth knowing before you plan:

- **An endpoint is routing configuration, nothing more.** Creating it does not make the service
  available. A worker in the target namespace must poll `worker_target.task_queue` and register a Nexus
  service; until it does, callers get an unimplemented error rather than a configuration error.
- **`description` is marked sensitive by the provider.** Terraform redacts it from plan and apply
  output, and this module's `nexus_endpoint_description` output is `sensitive = true` as a result. Read
  it with `terraform output -raw nexus_endpoint_description`, or `nonsensitive()` in an expression. It
  is *not* a secret in Temporal Cloud — the value is shown in the UI.
- **Endpoint names allow hyphens but not underscores**, must start with a letter and end with a letter
  or digit, and are unique within the account. The name is what callers address, so treat a rename as a
  breaking change for them.
- **Everything must be in one account.** Cross-account Nexus is not expressible here: the target
  namespace, the caller namespaces and the endpoint all belong to the same Temporal Cloud account.
- **Deleting a namespace out from under an endpoint leaves it broken.** Terraform orders this correctly
  when the endpoint references the namespace's output; it cannot when the namespace lives in another
  state.

## Examples

- [complete](examples/complete) — two namespaces and the endpoint routing between them, with multiple
  allowed callers, wired from the namespace module's outputs
- [single-caller](examples/single-caller) — the minimal endpoint, against namespaces that already exist

## Managing several endpoints

The [`wrappers`](wrappers) submodule creates many endpoints from one call, for use with Terragrunt or
anywhere a `for_each` on the module block is awkward:

```hcl
module "nexus_endpoints" {
  source  = "terraform-temporalcloud-modules/nexus-endpoint/temporalcloud//wrappers"
  version = "~> 1.0"

  defaults = {
    allowed_caller_namespaces = ["web-prod.a1b2c"]
  }

  items = {
    payments = {
      name          = "payments-prod"
      worker_target = { namespace_id = "payments-prod.a1b2c", task_queue = "payments-nexus" }
    }
    shipping = {
      name          = "shipping-prod"
      worker_target = { namespace_id = "shipping-prod.a1b2c", task_queue = "shipping-nexus" }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_temporalcloud"></a> [temporalcloud](#provider\_temporalcloud) | >= 1.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [temporalcloud_nexus_endpoint.this](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/resources/nexus_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_caller_namespaces"></a> [allowed\_caller\_namespaces](#input\_allowed\_caller\_namespaces) | Namespace IDs permitted to call this endpoint, each in the form `<namespace>.<account_id>`. Callers not listed here are rejected. A namespace that calls its own endpoint must still be listed. Required unless `create_nexus_endpoint` is `false` | `set(string)` | `[]` | no |
| <a name="input_create_nexus_endpoint"></a> [create\_nexus\_endpoint](#input\_create\_nexus\_endpoint) | Controls if the Nexus endpoint should be created. Set to `false` to disable the module without removing the call | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the endpoint, shown in the Temporal Cloud UI. The provider marks this attribute sensitive, so Terraform redacts it from plan and apply output and the module's `nexus_endpoint_description` output is sensitive in turn. It is not treated as a secret by Temporal Cloud | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Nexus endpoint. Must be unique within the account, start with a letter, end with a letter or digit, and contain only letters, digits and hyphens. Underscores are not accepted. Required unless `create_nexus_endpoint` is `false` | `string` | `""` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Create and delete timeouts, as duration strings such as `30s` or `2h45m` | <pre>object({<br/>    create = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_worker_target"></a> [worker\_target](#input\_worker\_target) | Where the endpoint routes incoming Nexus requests: the namespace whose workers serve them, and the task queue they poll. `namespace_id` is a namespace **ID** in the form `<namespace>.<account_id>` — the `id` attribute of `temporalcloud_namespace`, not the namespace name — and must be in the same account as the endpoint. Required unless `create_nexus_endpoint` is `false` | <pre>object({<br/>    namespace_id = string<br/>    task_queue   = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nexus_endpoint_allowed_caller_namespaces"></a> [nexus\_endpoint\_allowed\_caller\_namespaces](#output\_nexus\_endpoint\_allowed\_caller\_namespaces) | The IDs of the namespaces permitted to call this endpoint |
| <a name="output_nexus_endpoint_description"></a> [nexus\_endpoint\_description](#output\_nexus\_endpoint\_description) | The description of the Nexus endpoint. Marked sensitive because the provider marks the underlying attribute sensitive; read it with `terraform output -raw` or `nonsensitive()` |
| <a name="output_nexus_endpoint_id"></a> [nexus\_endpoint\_id](#output\_nexus\_endpoint\_id) | The unique identifier of the Nexus endpoint |
| <a name="output_nexus_endpoint_name"></a> [nexus\_endpoint\_name](#output\_nexus\_endpoint\_name) | The name of the Nexus endpoint. This is the name callers address in `NexusClient` / `nexus_service` configuration |
| <a name="output_nexus_endpoint_target_namespace_id"></a> [nexus\_endpoint\_target\_namespace\_id](#output\_nexus\_endpoint\_target\_namespace\_id) | The ID of the namespace whose workers serve requests to this endpoint, in the form `<namespace>.<account_id>` |
| <a name="output_nexus_endpoint_target_task_queue"></a> [nexus\_endpoint\_target\_task\_queue](#output\_nexus\_endpoint\_target\_task\_queue) | The task queue the target namespace's Nexus workers must poll to serve this endpoint |
| <a name="output_nexus_endpoint_worker_target"></a> [nexus\_endpoint\_worker\_target](#output\_nexus\_endpoint\_worker\_target) | The endpoint's routing target, as an object of `namespace_id` and `task_queue` |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow, how the test layers are arranged,
and the Temporal Cloud API behaviours the tests exist to guard against.

## License

Apache-2.0 licensed. See [LICENSE](LICENSE).
