variable "target_namespace_id" {
  description = "ID of the namespace whose workers serve the endpoint, in the form `<namespace>.<account_id>`. This is the `namespace_id` output of the namespace module, or the `id` column in the Temporal Cloud UI — not the namespace name"
  type        = string
}

variable "caller_namespace_id" {
  description = "ID of the single namespace permitted to call the endpoint, in the form `<namespace>.<account_id>`"
  type        = string
}
