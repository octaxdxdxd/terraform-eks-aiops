module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "vpc-${local.name_suffix}"
  cidr = "10.0.0.0/19"

  azs                  = ["${local.region}a", "${local.region}b"]
  private_subnets      = ["10.0.0.0/24", "10.0.4.0/24"]
  public_subnets       = ["10.0.6.0/24", "10.0.8.0/24"]
  private_subnet_names = ["private-subnet-a-${local.name_suffix}", "private-subnet-b-${local.name_suffix}"]
  public_subnet_names  = ["public-subnet-a-${local.name_suffix}", "public-subnet-b-${local.name_suffix}"]

  private_route_table_tags = {
    Name = "private-rt-${local.name_suffix}"
  }

  public_route_table_tags = {
    Name = "public-rt-${local.name_suffix}"
  }

  igw_tags = {
    Name = "igw-${local.name_suffix}"
  }

  nat_gateway_tags = {
    Name = "nat-${local.name_suffix}"
  }

  enable_nat_gateway = true
  single_nat_gateway = true
  reuse_nat_ips      = false

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = local.eks.cluster_name
  cluster_version = local.eks.cluster_version

  create_cloudwatch_log_group              = local.eks.create_cloudwatch_log_group
  enable_irsa                              = local.eks.enable_irsa
  cluster_endpoint_private_access          = local.eks.cluster_endpoint_private_access
  cluster_endpoint_public_access           = local.eks.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs     = local.eks.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = local.eks.enable_cluster_creator_admin_permissions

  cluster_addons = local.eks.cluster_addons

  create_kms_key                      = local.eks.create_kms_key
  enable_kms_key_rotation             = local.eks.enable_kms_key_rotation
  cluster_encryption_config           = local.eks.cluster_encryption_config
  attach_cluster_encryption_policy    = local.eks.attach_cluster_encryption_policy
  kms_key_enable_default_policy       = local.eks.kms_key_enable_default_policy
  iam_role_name                       = "cluster-role-${local.name_suffix}"
  iam_role_use_name_prefix            = false
  security_group_name                 = "cluster-sg-${local.name_suffix}"
  security_group_use_name_prefix      = false
  node_security_group_name            = "node-sg-${local.name_suffix}"
  node_security_group_use_name_prefix = false

  vpc_id                   = local.eks.vpc_id
  subnet_ids               = local.eks.subnet_ids
  control_plane_subnet_ids = local.eks.control_plane_subnet_ids

  eks_managed_node_group_defaults = local.eks.eks_managed_node_group_defaults
  eks_managed_node_groups         = local.eks.eks_managed_node_groups
  tags                            = local.tags
}

module "cert_manager" {
  source           = "./modules/helm_releases"
  chart            = local.helm_releases.cert_manager.chart
  name             = local.helm_releases.cert_manager.name
  repository       = local.helm_releases.cert_manager.repository
  chart_version    = local.helm_releases.cert_manager.chart_version
  namespace        = local.helm_releases.cert_manager.namespace
  create_namespace = local.helm_releases.cert_manager.create_namespace
  sets             = local.helm_releases.cert_manager.sets
}

resource "time_sleep" "cert_manager_crds" {
  create_duration = local.readiness.cert_manager_crd_wait

  depends_on = [module.cert_manager]
}

resource "kubectl_manifest" "letsencrypt_prod" {
  yaml_body = templatefile("${path.module}/manifests/letsencrypt-prod.yaml", {
    acme_email = local.acme_email
  })

  depends_on = [time_sleep.cert_manager_crds]
}

resource "kubectl_manifest" "letsencrypt_staging" {
  # staging issuer for testing without hitting prod ACME rate limits
  yaml_body = templatefile("${path.module}/manifests/letsencrypt-staging.yaml", {
    acme_email = local.acme_email
  })

  depends_on = [time_sleep.cert_manager_crds]
}

module "kong" {
  source           = "./modules/helm_releases"
  chart            = local.helm_releases.kong.chart
  name             = local.helm_releases.kong.name
  repository       = local.helm_releases.kong.repository
  chart_version    = local.helm_releases.kong.chart_version
  namespace        = local.helm_releases.kong.namespace
  create_namespace = local.helm_releases.kong.create_namespace
  sets             = local.helm_releases.kong.sets
}

module "kube_prometheus_stack" {
  source           = "./modules/helm_releases"
  chart            = local.helm_releases.kube_prometheus_stack.chart
  name             = local.helm_releases.kube_prometheus_stack.name
  repository       = local.helm_releases.kube_prometheus_stack.repository
  chart_version    = local.helm_releases.kube_prometheus_stack.chart_version
  namespace        = local.helm_releases.kube_prometheus_stack.namespace
  create_namespace = local.helm_releases.kube_prometheus_stack.create_namespace
  sets             = local.helm_releases.kube_prometheus_stack.sets
  wait             = local.helm_releases.kube_prometheus_stack.wait
  wait_for_jobs    = local.helm_releases.kube_prometheus_stack.wait_for_jobs
  timeout          = local.helm_releases.kube_prometheus_stack.timeout

  depends_on = [module.kong, kubectl_manifest.letsencrypt_prod, module.route53]
}

module "gitlab" {
  source           = "./modules/helm_releases"
  chart            = local.helm_releases.gitlab.chart
  name             = local.helm_releases.gitlab.name
  repository       = local.helm_releases.gitlab.repository
  chart_version    = local.helm_releases.gitlab.chart_version
  namespace        = local.helm_releases.gitlab.namespace
  create_namespace = local.helm_releases.gitlab.create_namespace
  sets             = local.helm_releases.gitlab.sets
  wait             = local.helm_releases.gitlab.wait
  wait_for_jobs    = local.helm_releases.gitlab.wait_for_jobs
  timeout          = local.helm_releases.gitlab.timeout

  depends_on = [module.kong, time_sleep.cert_manager_crds, module.route53]
}

module "jenkins" {
  source           = "./modules/helm_releases"
  chart            = local.helm_releases.jenkins.chart
  name             = local.helm_releases.jenkins.name
  repository       = local.helm_releases.jenkins.repository
  chart_version    = local.helm_releases.jenkins.chart_version
  namespace        = local.helm_releases.jenkins.namespace
  create_namespace = local.helm_releases.jenkins.create_namespace
  sets             = local.helm_releases.jenkins.sets
  wait             = local.helm_releases.jenkins.wait
  timeout          = local.helm_releases.jenkins.timeout

  depends_on = [module.kong, kubectl_manifest.letsencrypt_prod, module.route53]
}

module "nexus" {
  source           = "./modules/helm_releases"
  chart            = local.helm_releases.nexus.chart
  name             = local.helm_releases.nexus.name
  repository       = local.helm_releases.nexus.repository
  chart_version    = local.helm_releases.nexus.chart_version
  namespace        = local.helm_releases.nexus.namespace
  create_namespace = local.helm_releases.nexus.create_namespace
  sets             = local.helm_releases.nexus.sets
  wait             = local.helm_releases.nexus.wait
  wait_for_jobs    = local.helm_releases.nexus.wait_for_jobs
  timeout          = local.helm_releases.nexus.timeout

  depends_on = [module.kong, kubectl_manifest.letsencrypt_prod, module.route53]
}

module "route53" {
  source              = "./modules/route53"
  zone_name           = local.route53.zone_name
  gitlab_name         = local.route53.gitlab_name
  nexus_record        = local.route53.nexus_record
  nexus_docker_record = local.route53.nexus_docker_record
  jenkins_record      = local.route53.jenkins_record
  minio_record        = local.route53.minio_record
  grafana_record      = local.route53.grafana_record
  records             = local.route53.records
}

resource "kubectl_manifest" "gitlab_shell_tcp_ingress" {
  # SSH needs TCPIngress — can't route through normal HTTP ingress
  yaml_body = <<YAML
apiVersion: configuration.konghq.com/v1beta1
kind: TCPIngress
metadata:
  name: gitlab-shell
  namespace: gitlab
  annotations:
    kubernetes.io/ingress.class: kong
spec:
  rules:
    - port: 22
      backend:
        serviceName: gitlab-gitlab-shell
        servicePort: 22
YAML

  depends_on = [module.kong, module.gitlab]
}

resource "kubectl_manifest" "nexus_docker_ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nexus-docker
  namespace: nexus
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    konghq.com/https-redirect-status-code: "308"
    konghq.com/strip-path: "false"
spec:
  ingressClassName: kong
  tls:
    - hosts:
        - docker.nexus.test.${local.domain}
      secretName: nexus-docker-tls
  rules:
    - host: docker.nexus.test.${local.domain}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nexus-nexus-repository-manager-docker-5000
                port:
                  number: 5000
YAML

  depends_on = [module.kong, kubectl_manifest.letsencrypt_prod, module.nexus, module.route53]
}

resource "aws_autoscaling_group_tag" "general_asg_tags" {
  for_each = merge(local.tags, {
    Name = "asg-${local.name_suffix}"
  })

  autoscaling_group_name = module.eks.eks_managed_node_groups_autoscaling_group_name[0]

  tag {
    key                 = each.key
    value               = each.value
    propagate_at_launch = true
  }

  depends_on = [module.eks]
}

resource "aws_iam_role" "devops_agent" {
  name = var.devops_agent_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_eks_access_entry" "devops_agent" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.devops_agent.arn
}

resource "aws_eks_access_policy_association" "devops_agent" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.devops_agent.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.devops_agent]
}

resource "aws_eks_access_policy_association" "devops_agent_aiops" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.devops_agent.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonAIOpsAssistantPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.devops_agent]
}
