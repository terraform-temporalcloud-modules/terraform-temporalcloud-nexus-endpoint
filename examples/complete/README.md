# Complete Temporal Cloud Nexus endpoint example

Configuration in this directory creates two namespaces — one serving a Nexus service, one calling it —
and the Nexus endpoint that routes between them.

Both sides of the endpoint are namespace **IDs**, in the form `<namespace>.<account_id>`. They come
from the namespace module's `namespace_id` output rather than being typed by hand, which is the point
of the example: a bare namespace name looks correct and is rejected by the API.

The `regions` values must be ones your account is entitled to use — see
[Choosing regions](../../README.md#choosing-regions) if apply reports an invalid region.

## Usage

To run this example you need to execute:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"

terraform init
terraform plan
terraform apply
```

Note that this example creates resources which cost money. Run `terraform destroy` when you no longer
need them.

The endpoint is routing configuration only. Nothing serves it until a worker in the payments namespace
polls the `payments-nexus` task queue and registers a Nexus service — until then, callers get an
unimplemented error rather than a configuration error.

The `description` is redacted from plan and apply output. The provider marks that attribute sensitive.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_temporalcloud"></a> [temporalcloud](#requirement\_temporalcloud) | >= 1.6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_nexus_endpoint"></a> [nexus\_endpoint](#module\_nexus\_endpoint) | terraform-temporalcloud-modules/nexus-endpoint/temporalcloud | ~> 1.0 |
| <a name="module_payments_namespace"></a> [payments\_namespace](#module\_payments\_namespace) | terraform-temporalcloud-modules/namespace/temporalcloud | ~> 1.0 |
| <a name="module_web_namespace"></a> [web\_namespace](#module\_web\_namespace) | terraform-temporalcloud-modules/namespace/temporalcloud | ~> 1.0 |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nexus_endpoint_allowed_caller_namespaces"></a> [nexus\_endpoint\_allowed\_caller\_namespaces](#output\_nexus\_endpoint\_allowed\_caller\_namespaces) | The namespace IDs permitted to call this endpoint |
| <a name="output_nexus_endpoint_id"></a> [nexus\_endpoint\_id](#output\_nexus\_endpoint\_id) | The unique identifier of the Nexus endpoint |
| <a name="output_nexus_endpoint_name"></a> [nexus\_endpoint\_name](#output\_nexus\_endpoint\_name) | The endpoint name callers address when they create a Nexus client |
| <a name="output_nexus_endpoint_target_namespace_id"></a> [nexus\_endpoint\_target\_namespace\_id](#output\_nexus\_endpoint\_target\_namespace\_id) | The ID of the namespace whose workers serve this endpoint |
| <a name="output_nexus_endpoint_target_task_queue"></a> [nexus\_endpoint\_target\_task\_queue](#output\_nexus\_endpoint\_target\_task\_queue) | The task queue the payments workers must poll |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
