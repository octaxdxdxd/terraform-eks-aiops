# route53

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.14.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.25.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.25.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route53_record.grafana_record](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/route53_record) | resource |
| [aws_route53_record.jenkins_record](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/route53_record) | resource |
| [aws_route53_record.minio_record](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/route53_record) | resource |
| [aws_route53_record.nexus_docker_record](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/route53_record) | resource |
| [aws_route53_record.nexus_record](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/route53_record) | resource |
| [aws_route53_record.www](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/route53_record) | resource |
| [aws_route53_zone.selected](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_gitlab_name"></a> [gitlab\_name](#input\_gitlab\_name) | n/a | `string` | n/a | yes |
| <a name="input_grafana_record"></a> [grafana\_record](#input\_grafana\_record) | n/a | `string` | n/a | yes |
| <a name="input_jenkins_record"></a> [jenkins\_record](#input\_jenkins\_record) | n/a | `string` | n/a | yes |
| <a name="input_minio_record"></a> [minio\_record](#input\_minio\_record) | n/a | `string` | n/a | yes |
| <a name="input_nexus_docker_record"></a> [nexus\_docker\_record](#input\_nexus\_docker\_record) | n/a | `string` | n/a | yes |
| <a name="input_nexus_record"></a> [nexus\_record](#input\_nexus\_record) | n/a | `string` | n/a | yes |
| <a name="input_records"></a> [records](#input\_records) | n/a | `list(string)` | n/a | yes |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | The Route53 hosted zone domain name (e.g. your-domain.com) | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
