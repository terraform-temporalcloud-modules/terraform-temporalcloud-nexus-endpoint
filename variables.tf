variable "create_nexus_endpoint" {
  description = "Controls if the Nexus endpoint should be created. Set to `false` to disable the module without removing the call"
  type        = bool
  default     = true
}

################################################################################
# Nexus endpoint
################################################################################

variable "name" {
  description = "The name of the Nexus endpoint. Must be unique within the account, start with a letter, end with a letter or digit, and contain only letters, digits and hyphens. Underscores are not accepted. Required unless `create_nexus_endpoint` is `false`"
  type        = string
  default     = ""

  # Mirrors the provider's constraint so a malformed name fails during plan
  # rather than after a round trip to the Temporal Cloud API.
  validation {
    condition     = var.name == "" || can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name))
    error_message = "The endpoint name must start with a letter, end with a letter or digit, and contain only letters, digits and hyphens."
  }
}

variable "worker_target" {
  description = "Where the endpoint routes incoming Nexus requests: the namespace whose workers serve them, and the task queue they poll. `namespace_id` is a namespace **ID** in the form `<namespace>.<account_id>` — the `id` attribute of `temporalcloud_namespace`, not the namespace name — and must be in the same account as the endpoint. Required unless `create_nexus_endpoint` is `false`"
  type = object({
    namespace_id = string
    task_queue   = string
  })
  default = null

  # try() supplies a placeholder that passes, so a null `worker_target` — valid
  # when `create_nexus_endpoint` is `false` — does not trip this check.
  validation {
    condition     = can(regex("^[^.]+\\.[^.]+$", try(var.worker_target.namespace_id, "namespace.account")))
    error_message = "worker_target.namespace_id must be a namespace ID in the form `<namespace>.<account_id>`, for example `orders-prod.a1b2c`. A bare namespace name is not a namespace ID. Use the `namespace_id` output of the namespace module, or the `id` attribute of a `temporalcloud_namespace` resource or data source."
  }

  validation {
    condition     = try(var.worker_target.task_queue, "placeholder") != ""
    error_message = "worker_target.task_queue must name the task queue the target namespace's Nexus workers poll, and cannot be empty."
  }
}

variable "allowed_caller_namespaces" {
  description = "Namespace IDs permitted to call this endpoint, each in the form `<namespace>.<account_id>`. Callers not listed here are rejected. A namespace that calls its own endpoint must still be listed. Required unless `create_nexus_endpoint` is `false`"
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.allowed_caller_namespaces : can(regex("^[^.]+\\.[^.]+$", id))
    ])
    error_message = "Every entry in allowed_caller_namespaces must be a namespace ID in the form `<namespace>.<account_id>`, for example `web-prod.a1b2c`. A bare namespace name is not a namespace ID."
  }
}

variable "description" {
  description = "Description of the endpoint, shown in the Temporal Cloud UI. The provider marks this attribute sensitive, so Terraform redacts it from plan and apply output and the module's `nexus_endpoint_description` output is sensitive in turn. It is not treated as a secret by Temporal Cloud"
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Create and delete timeouts, as duration strings such as `30s` or `2h45m`"
  type = object({
    create = optional(string)
    delete = optional(string)
  })
  default = {}
}
