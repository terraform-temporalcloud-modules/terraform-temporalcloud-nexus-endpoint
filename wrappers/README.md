# Wrapper for the Temporal Cloud Nexus endpoint module

The configuration in `wrappers/` implements the single module wrapper pattern, which allows managing
several copies of this module from one call in places where the native `for_each` on a module block is
not available — most commonly Terragrunt.

This wrapper adds no functionality of its own. Every key under `items` accepts any input the root
module accepts, and `defaults` supplies values shared by all items.

Contributors: see [CONTRIBUTING.md](../CONTRIBUTING.md) for how these files are maintained.

## Usage with Terraform

Namespace IDs are `<namespace>.<account_id>`, not bare namespace names. `defaults` is a good home for
`allowed_caller_namespaces` when a set of endpoints shares the same callers.

```hcl
module "nexus_endpoints" {
  source  = "terraform-temporalcloud-modules/nexus-endpoint/temporalcloud//wrappers"

  # Shared by every item unless the item overrides it.
  defaults = {
    allowed_caller_namespaces = [
      "web-prod.a1b2c",
      "mobile-prod.a1b2c",
    ]
  }

  items = {
    payments = {
      name = "payments-prod"

      worker_target = {
        namespace_id = "payments-prod.a1b2c"
        task_queue   = "payments-nexus"
      }
    }

    shipping = {
      name        = "shipping-prod"
      description = "Shipping quotes and label creation"

      worker_target = {
        namespace_id = "shipping-prod.a1b2c"
        task_queue   = "shipping-nexus"
      }

      # Overrides the shared default above: only the web front end may call this.
      allowed_caller_namespaces = ["web-prod.a1b2c"]
    }
  }
}
```

Outputs are keyed by the same map keys:

```hcl
output "payments_endpoint_name" {
  value = module.nexus_endpoints.wrapper["payments"].nexus_endpoint_name
}
```

## Usage with Terragrunt

`terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///terraform-temporalcloud-modules/nexus-endpoint/temporalcloud//wrappers?version=1.0.0"
  # Alternative source:
  # source = "git::git@github.com:terraform-temporalcloud-modules/terraform-temporalcloud-nexus-endpoint.git//wrappers?ref=v1.0.0"
}

inputs = {
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

Pin `?version=` / `?ref=` to a released tag rather than a branch, so a wrapper upgrade is a deliberate
change.

## Inputs

| Name | Description | Type | Default |
| ---- | ----------- | ---- | ------- |
| `defaults` | Default values applied to every Nexus endpoint in `items`, unless that item overrides them | `any` | `{}` |
| `items` | Map of Nexus endpoints to create; each key becomes an instance of the module | `any` | `{}` |

## Outputs

| Name | Description |
| ---- | ----------- |
| `wrapper` | Map of module outputs, keyed by the same keys as `items` |
