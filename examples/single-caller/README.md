# Single-caller Temporal Cloud Nexus endpoint example

The smallest useful Nexus endpoint: one caller namespace, one target namespace, one task queue.

Unlike the [complete](../complete) example, this one does not create the namespaces. It takes their
IDs as input, which is the usual shape once namespaces are owned by a platform team and the endpoint
is owned by a service team. Each ID is looked up with `data.temporalcloud_namespace` so a wrong or
misspelled ID fails at plan rather than at apply.

Both IDs are of the form `<namespace>.<account_id>` — for example `payments-prod.a1b2c`. A bare
namespace name is not a namespace ID.

## Usage

To run this example you need to execute:

```bash
export TEMPORAL_CLOUD_API_KEY="<your-api-key>"

terraform init
terraform plan  -var 'target_namespace_id=payments-prod.a1b2c' -var 'caller_namespace_id=web-prod.a1b2c'
terraform apply -var 'target_namespace_id=payments-prod.a1b2c' -var 'caller_namespace_id=web-prod.a1b2c'
```

If you manage the namespaces with the
[namespace module](https://registry.terraform.io/modules/terraform-temporalcloud-modules/namespace/temporalcloud),
read the IDs from it instead of typing them:

```bash
terraform -chdir=../namespaces output -raw namespace_id
```

Note that this example creates resources which cost money. Run `terraform destroy` when you no longer
need them.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_nexus_endpoint"></a> [nexus\_endpoint](#module\_nexus\_endpoint) | terraform-temporalcloud-modules/nexus-endpoint/temporalcloud | ~> 1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [temporalcloud_namespace.caller](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/data-sources/namespace) | data source |
| [temporalcloud_namespace.target](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs/data-sources/namespace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_caller_namespace_id"></a> [caller\_namespace\_id](#input\_caller\_namespace\_id) | ID of the single namespace permitted to call the endpoint, in the form `<namespace>.<account_id>` | `string` | n/a | yes |
| <a name="input_target_namespace_id"></a> [target\_namespace\_id](#input\_target\_namespace\_id) | ID of the namespace whose workers serve the endpoint, in the form `<namespace>.<account_id>`. This is the `namespace_id` output of the namespace module, or the `id` column in the Temporal Cloud UI — not the namespace name | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nexus_endpoint_id"></a> [nexus\_endpoint\_id](#output\_nexus\_endpoint\_id) | The unique identifier of the Nexus endpoint |
| <a name="output_nexus_endpoint_name"></a> [nexus\_endpoint\_name](#output\_nexus\_endpoint\_name) | The endpoint name the caller addresses when it creates a Nexus client |
| <a name="output_nexus_endpoint_target_task_queue"></a> [nexus\_endpoint\_target\_task\_queue](#output\_nexus\_endpoint\_target\_task\_queue) | The task queue the target namespace's workers must poll |
<!-- END_TF_DOCS -->

## License

Apache-2.0 licensed. See [LICENSE](../../LICENSE).
