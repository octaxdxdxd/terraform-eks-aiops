# helm_releases

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.14.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~>2.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart"></a> [chart](#input\_chart) | Chart name | `string` | n/a | yes |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Chart version to install | `string` | `null` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create the namespace | `bool` | n/a | yes |
| <a name="input_dependency_update"></a> [dependency\_update](#input\_dependency\_update) | n/a | `bool` | `false` | no |
| <a name="input_force_update"></a> [force\_update](#input\_force\_update) | n/a | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for the release | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | Helm chart repository URL | `string` | `null` | no |
| <a name="input_sets"></a> [sets](#input\_sets) | List of name/value pairs for set | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    type  = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Time in seconds to wait for Helm release operations | `number` | `null` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | n/a | `bool` | `true` | no |
| <a name="input_wait_for_jobs"></a> [wait\_for\_jobs](#input\_wait\_for\_jobs) | n/a | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
