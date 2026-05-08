# Terraform AWS EKS Stack

[![Terraform CI](https://github.com/octaxdxdxd/terraform-eks-aiops/actions/workflows/terraform.yml/badge.svg)](https://github.com/octaxdxdxd/terraform-eks-aiops/actions/workflows/terraform.yml)

Production-grade AWS EKS infrastructure provisioned entirely with Terraform. Deploys a full DevOps platform — Kong ingress, TLS via cert-manager, Route53 DNS, GitLab CE, Jenkins, Nexus, and Prometheus/Grafana monitoring — across isolated dev and prod environments using Terraform workspaces.

**Key practices:**
- **Modular design** — reusable modules for EKS, Helm releases, Route53, and security groups; all configuration centralised in `locals.tf`
- **Environment separation** — `dev` and `prod` workspaces share the same codebase with per-environment `.tfvars`; service subdomains (`nexus.dev.example.com` vs `nexus.example.com`) driven by a single variable
- **DevSecOps** — pre-commit pipeline with `checkov` (IaC policy), `trivy` (vulnerability scanning), `tflint` (linting), `terraform-docs` (auto-docs), and `infracost` (cost estimation); GitHub Actions CI validates and plans on every PR
- **Security** — NLB and EKS API endpoint locked to configurable CIDRs; least-privilege RBAC for pod GC; TLS everywhere via Let's Encrypt; S3 remote state with versioning and public access blocked

## Architecture

### What gets created

| Layer | Resources |
|---|---|
| **Networking** | VPC, 2× private + 2× public subnets across 2 AZs, single NAT gateway, route tables, IGW |
| **Compute** | EKS cluster (v1.35), managed node group (`t3.large`, on-demand, ×3 desired / ×2 min) |
| **EKS add-ons** | `aws-ebs-csi-driver` (Pod Identity), `coredns`, `kube-proxy`, `vpc-cni`, `eks-pod-identity-agent` |
| **Ingress** | Kong Gateway (Helm) exposed via AWS NLB; TCP stream rule on port 22 for GitLab SSH |
| **TLS** | cert-manager (Helm) + Let's Encrypt `ClusterIssuer` for prod and staging ACME endpoints |
| **DNS** | Route53 CNAME records — all service subdomains point at the Kong NLB hostname |
| **Applications** | GitLab CE, Jenkins, Nexus Repository Manager — each with HTTPS ingress + auto-cert |
| **Monitoring** | kube-prometheus-stack: Prometheus (EBS-backed, bounded retention) + Grafana (EBS-backed) |
| **Cleanup** | CronJob in `kube-system` that purges `Failed`/`Unknown`/`Succeeded` pods every 30 minutes |
| **Access** | EKS access entries grant the DevOps agent role `AmazonEKSAdminViewPolicy` + `AmazonAIOpsAssistantPolicy` |

### How traffic flows

```
Browser / CLI
      │
      ▼
AWS NLB  ←─── Kong Gateway (Helm, kong namespace)
      │              │
      │         Kong Ingress Controller
      │         routes by Host header
      │
      ├── gitlab.test.<domain>   → GitLab (gitlab namespace)
      ├── jenkins.test.<domain>  → Jenkins (jenkins namespace)
      ├── nexus.test.<domain>    → Nexus UI (nexus namespace)
      ├── docker.nexus.test.<domain> → Nexus Docker registry (port 5000 internally)
      └── grafana.test.<domain>  → Grafana (monitoring namespace)
```

TLS is terminated at the ingress layer. cert-manager watches `cert-manager.io/cluster-issuer` annotations on Ingress objects and requests certificates from Let's Encrypt using the HTTP-01 ACME challenge routed through Kong.

GitLab SSH (port 22) is handled separately via a `TCPIngress` resource that bypasses HTTP routing entirely.

### Apply dependency order

Terraform enforces this ordering via `depends_on` and `time_sleep` resources:

1. **VPC** → subnets, route tables, NAT, IGW
2. **EKS cluster** → node group, add-ons, IAM roles, security groups
3. **cert-manager** Helm release → `30s` sleep (lets CRDs register cluster-wide)
4. **Let's Encrypt ClusterIssuers** (prod + staging) — requires CRDs from step 3
5. **Kong** Helm release → `90s` sleep (waits for NLB to provision and get a hostname)
6. **Route53** CNAME records — requires Kong NLB hostname from step 5
7. **GitLab, Jenkins, Nexus, kube-prometheus-stack** — run in parallel; each requires Kong + Route53 so ACME HTTP-01 challenges can resolve
8. **GitLab TCPIngress** (SSH port 22), **Nexus Docker HTTPS Ingress** — applied after their respective app releases
9. **Pod GC** CronJob + ServiceAccount + RBAC — applied after EKS is ready

## Repository Structure

```
.
├── backend.tf          # S3 remote state backend (workspace-aware)
├── providers.tf        # Required providers + AWS / Kubernetes / Helm / kubectl config
├── variables.tf        # Input variables — set values in environments/*.tfvars
├── locals.tf           # All derived config in one place; edit here to customise
├── main.tf             # Module calls and top-level resources
├── data.tf             # Data source: Kong NLB lookup (by tag)
├── outputs.tf          # Kong NLB hostname output
├── pod_gc.tf           # Terminated pod GC kubectl manifests
├── environments/
│   ├── dev.tfvars      # Dev environment variable values
│   └── prod.tfvars     # Prod environment variable values
├── manifests/          # Raw Kubernetes YAML (pod GC ServiceAccount, ClusterRole, CronJob)
└── modules/
    ├── eks/            # Wraps terraform-aws-modules/eks/aws
    ├── helm_releases/  # Generic Helm release wrapper (dynamic set{} blocks)
    ├── route53/        # Route53 CNAME records for all service subdomains
    └── security_group/ # Security group helper
```

## Configuration

### Variables (`variables.tf`)

All environment-specific values are declared as variables and supplied via `environments/*.tfvars`.

| Variable | Description | Example |
|---|---|---|
| `aws_account_id` | AWS account ID — used to construct IAM ARNs | `123456789012` |
| `devops_agent_role_name` | IAM role name for the DevOps agent (no path prefix) | `MyAgentRole` |
| `domain` | Root Route53 hosted zone domain | `example.com` |
| `acme_email` | Email registered with Let's Encrypt | `ops@example.com` |
| `allowed_cidrs` | CIDRs allowed to reach the EKS endpoint and Kong NLB | `["1.2.3.4/32"]` |
| `name_suffix` | Suffix on all AWS resource names | `project-dev` |

### Locals (`locals.tf`)

`locals.tf` derives everything else: IAM ARNs are constructed from `aws_account_id` + `devops_agent_role_name`, all Helm `set` entries reference `local.domain`, `allowed_cidrs` is expanded into numbered Kong `loadBalancerSourceRanges` entries dynamically via a `for` expression. Changing a variable propagates through the entire configuration automatically.

## Environments & Workspaces

This repo uses [Terraform workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces) to isolate state per environment within the same S3 bucket. Non-default workspaces are stored at `env:/<workspace>/terraform/terraform.tfstate` automatically by the S3 backend.

### Bootstrap (one-time)

Before running `terraform init`, the S3 bucket referenced in `backend.tf` must exist. Create it manually once:

```bash
aws s3api create-bucket \
  --bucket <your-bucket-name> \
  --region us-east-1

# Enable versioning so state history is preserved
aws s3api put-bucket-versioning \
  --bucket <your-bucket-name> \
  --versioning-configuration Status=Enabled

# Block all public access
aws s3api put-public-access-block \
  --bucket <your-bucket-name> \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

Then update the `bucket` value in `backend.tf` to match.

### Workspace setup (first time)

```bash
terraform init
terraform workspace new dev
terraform workspace new prod
```

### Deploy

```bash
# Dev
terraform workspace select dev
terraform plan  -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Prod
terraform workspace select prod
terraform plan  -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

### Destroy an environment

```bash
terraform workspace select dev
terraform destroy -var-file=environments/dev.tfvars
```

## Terminated Pod Cleanup

EKS does not expose `kube-controller-manager` tuning, so pods in terminal states (`Failed`, `Unknown`, `Succeeded`) can accumulate after node stop/start cycles. A lightweight CronJob in `kube-system` runs every 30 minutes using `kubectl delete pods --field-selector` to clean these up. The CronJob runs as a non-root user with a minimal `ClusterRole` scoped to pod deletion only.

## Pre-commit Setup

This repository uses `pre-commit` with the hooks defined in `.pre-commit-config.yaml`.

### Required tools

The configured hooks require these tools to be available:

- `terraform`
- `pre-commit`
- `checkov`
- `terraform-docs`
- `tflint`
- `trivy`
- `infracost`

### Installation plan

Install these globally:

- `terraform`
- `terraform-docs`
- `tflint`
- `trivy`

Install these with `pipx`:

- `pre-commit`
- `checkov`

This keeps Python-based CLI tools isolated without affecting the normal Terraform development workflow.

### Install base dependencies

```bash
sudo apt update
sudo apt install -y python3 pipx curl unzip
```

Run this once after installing `pipx` so its binaries are available in your shell:

```bash
pipx ensurepath
```

Then open a new shell, or reload your shell configuration.

Install Terraform separately if it is not already available on your machine.

### Install Python-based CLI tools with pipx

```bash
pipx install pre-commit
pipx install checkov
```

### Install terraform-docs

```bash
curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz
tar -xzf terraform-docs.tgz terraform-docs
rm terraform-docs.tgz
chmod +x terraform-docs
sudo mv terraform-docs /usr/bin/
```

### Install tflint

```bash
curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip
unzip tflint.zip
rm tflint.zip
sudo mv tflint /usr/bin/
```

### Install trivy

```bash
curl -L "$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep -o -E -i -m 1 "https://.+?/trivy_.+?_Linux-64bit.tar.gz")" > trivy.tar.gz
tar -xzf trivy.tar.gz trivy
rm trivy.tar.gz
sudo mv trivy /usr/bin/
```

### Install Infracost

```bash
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
infracost auth login
```

The Infracost hook runs twice:
1. Generates `infracost-base.json` (cost baseline committed to the repo)
2. Displays a short cost diff in the terminal

### Install the Git hook

```bash
pre-commit install
```

You only need to run this once per clone.

### Run the hooks manually

```bash
pre-commit run -a
```

## Terraform DOCS
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.14.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.25.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~>2.17.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 1.19.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 3.00.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.13.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.1.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.25.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/helm_releases | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_gitlab"></a> [gitlab](#module\_gitlab) | ./modules/helm_releases | n/a |
| <a name="module_jenkins"></a> [jenkins](#module\_jenkins) | ./modules/helm_releases | n/a |
| <a name="module_kong"></a> [kong](#module\_kong) | ./modules/helm_releases | n/a |
| <a name="module_kube_prometheus_stack"></a> [kube\_prometheus\_stack](#module\_kube\_prometheus\_stack) | ./modules/helm_releases | n/a |
| <a name="module_nexus"></a> [nexus](#module\_nexus) | ./modules/helm_releases | n/a |
| <a name="module_route53"></a> [route53](#module\_route53) | ./modules/route53 | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 6.5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_autoscaling_group_tag.general_asg_tags](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/autoscaling_group_tag) | resource |
| [aws_eks_access_entry.devops_agent](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.devops_agent](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_access_policy_association.devops_agent_aiops](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/eks_access_policy_association) | resource |
| [aws_iam_role.devops_agent](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/resources/iam_role) | resource |
| [kubectl_manifest.gitlab_shell_tcp_ingress](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [kubectl_manifest.letsencrypt_prod](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [kubectl_manifest.letsencrypt_staging](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [kubectl_manifest.nexus_docker_ingress](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [kubectl_manifest.terminated_pod_gc_cluster_role](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [kubectl_manifest.terminated_pod_gc_cluster_role_binding](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [kubectl_manifest.terminated_pod_gc_cronjob](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [kubectl_manifest.terminated_pod_gc_service_account](https://registry.terraform.io/providers/gavinbunney/kubectl/1.19.0/docs/resources/manifest) | resource |
| [time_sleep.cert_manager_crds](https://registry.terraform.io/providers/hashicorp/time/0.13.1/docs/resources/sleep) | resource |
| [time_sleep.kong_load_balancer](https://registry.terraform.io/providers/hashicorp/time/0.13.1/docs/resources/sleep) | resource |
| [aws_lb.kong_proxy](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/data-sources/lb) | data source |
| [aws_lbs.kong_proxy](https://registry.terraform.io/providers/hashicorp/aws/6.25.0/docs/data-sources/lbs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acme_email"></a> [acme\_email](#input\_acme\_email) | Email address for Let's Encrypt ACME certificate registration | `string` | n/a | yes |
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | CIDR ranges allowed to reach the EKS API endpoint and Kong load balancer | `list(string)` | `[]` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account ID used to construct IAM role ARNs | `string` | n/a | yes |
| <a name="input_devops_agent_role_name"></a> [devops\_agent\_role\_name](#input\_devops\_agent\_role\_name) | Name of the IAM role used by the DevOps agent (without path prefix) | `string` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Root Route53 hosted zone domain (e.g. example.com) | `string` | n/a | yes |
| <a name="input_env_subdomain"></a> [env\_subdomain](#input\_env\_subdomain) | Subdomain prefix for this environment (e.g. 'dev' → nexus.dev.example.com). Leave empty for prod (nexus.example.com). | `string` | `""` | no |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Suffix appended to all AWS resource names to distinguish environments (e.g. project-dev, project-prod) | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_gitlab_url"></a> [gitlab\_url](#output\_gitlab\_url) | n/a |
| <a name="output_grafana_url"></a> [grafana\_url](#output\_grafana\_url) | n/a |
| <a name="output_jenkins_url"></a> [jenkins\_url](#output\_jenkins\_url) | n/a |
| <a name="output_kong_ingress_hostname"></a> [kong\_ingress\_hostname](#output\_kong\_ingress\_hostname) | n/a |
| <a name="output_nexus_docker_registry"></a> [nexus\_docker\_registry](#output\_nexus\_docker\_registry) | n/a |
| <a name="output_nexus_url"></a> [nexus\_url](#output\_nexus\_url) | n/a |
<!-- END_TF_DOCS -->
