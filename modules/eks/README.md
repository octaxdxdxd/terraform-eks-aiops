# eks

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.14.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 21.10.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_attach_cluster_encryption_policy"></a> [attach\_cluster\_encryption\_policy](#input\_attach\_cluster\_encryption\_policy) | n/a | `bool` | n/a | yes |
| <a name="input_cluster_addons"></a> [cluster\_addons](#input\_cluster\_addons) | n/a | `any` | n/a | yes |
| <a name="input_cluster_encryption_config"></a> [cluster\_encryption\_config](#input\_cluster\_encryption\_config) | n/a | `any` | `{}` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | n/a | `bool` | n/a | yes |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | n/a | `bool` | n/a | yes |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | n/a | `list(string)` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | n/a | `string` | n/a | yes |
| <a name="input_control_plane_subnet_ids"></a> [control\_plane\_subnet\_ids](#input\_control\_plane\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | n/a | `bool` | n/a | yes |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | n/a | `bool` | n/a | yes |
| <a name="input_eks_managed_node_group_defaults"></a> [eks\_managed\_node\_group\_defaults](#input\_eks\_managed\_node\_group\_defaults) | n/a | `any` | n/a | yes |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | n/a | `any` | n/a | yes |
| <a name="input_enable_cluster_creator_admin_permissions"></a> [enable\_cluster\_creator\_admin\_permissions](#input\_enable\_cluster\_creator\_admin\_permissions) | n/a | `bool` | n/a | yes |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | n/a | `bool` | n/a | yes |
| <a name="input_enable_kms_key_rotation"></a> [enable\_kms\_key\_rotation](#input\_enable\_kms\_key\_rotation) | n/a | `bool` | n/a | yes |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | n/a | `string` | `null` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | n/a | `bool` | `true` | no |
| <a name="input_kms_key_enable_default_policy"></a> [kms\_key\_enable\_default\_policy](#input\_kms\_key\_enable\_default\_policy) | n/a | `bool` | n/a | yes |
| <a name="input_node_security_group_name"></a> [node\_security\_group\_name](#input\_node\_security\_group\_name) | n/a | `string` | `null` | no |
| <a name="input_node_security_group_use_name_prefix"></a> [node\_security\_group\_use\_name\_prefix](#input\_node\_security\_group\_use\_name\_prefix) | n/a | `bool` | `true` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | n/a | `string` | `null` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | n/a | `bool` | `true` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_ca"></a> [cluster\_ca](#output\_cluster\_ca) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_cluster_oidc_issuer_arn"></a> [cluster\_oidc\_issuer\_arn](#output\_cluster\_oidc\_issuer\_arn) | n/a |
| <a name="output_cluster_url"></a> [cluster\_url](#output\_cluster\_url) | n/a |
| <a name="output_eks_managed_node_groups_autoscaling_group_name"></a> [eks\_managed\_node\_groups\_autoscaling\_group\_name](#output\_eks\_managed\_node\_groups\_autoscaling\_group\_name) | n/a |
<!-- END_TF_DOCS -->
