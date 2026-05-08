locals {
  region                 = "us-east-1"
  domain                 = var.domain
  env_subdomain          = var.env_subdomain
  fqdn                   = var.env_subdomain != "" ? "${var.env_subdomain}.${var.domain}" : var.domain
  aws_account_id         = var.aws_account_id
  devops_agent_role_name = var.devops_agent_role_name
  acme_email             = var.acme_email
  name_suffix            = var.name_suffix

  tags = {
    Owner     = "Octavian Popov"
    Purpose   = "Terraform EKS Demo"
    Terraform = "True"
  }

  iam = {
    ebs_csi_irsa_role_name = "AmazonEBSCSIDriverPolicy"
  }

  monitoring = {
    storage_class             = "ebs-csi-default-sc"
    grafana_storage_size      = "5Gi"
    prometheus_storage_size   = "10Gi"
    prometheus_retention      = "3d"
    prometheus_retention_size = "8GiB"
  }

  eks = {
    cluster_name                = "eks-${local.name_suffix}"
    cluster_version             = "1.35"
    create_cloudwatch_log_group = false
    # add-ons use pod identity, not IRSA
    enable_irsa                              = false
    enable_cluster_creator_admin_permissions = true
    cluster_endpoint_private_access          = true
    cluster_endpoint_public_access           = true
    cluster_endpoint_public_access_cidrs     = length(var.allowed_cidrs) > 0 ? var.allowed_cidrs : ["0.0.0.0/0"]


    cluster_addons = {
      aws-ebs-csi-driver = {
        most_recent = true
        pod_identity_association = [
          {
            role_arn        = "arn:aws:iam::${local.aws_account_id}:role/AmazonEKSPodIdentityAmazonEBSCSIDriverRole"
            service_account = "ebs-csi-controller-sa"
          }
        ]
        configuration_values = jsonencode({
          defaultStorageClass = { enabled = true }
        })
      }
      coredns = {
        most_recent = true
      }
      eks-pod-identity-agent = {
        before_compute = true
        most_recent    = true
      }
      kube-proxy = {
        most_recent = true
      }
      vpc-cni = {
        before_compute = true
        most_recent    = true
      }
    }

    create_kms_key                   = false
    enable_kms_key_rotation          = false
    cluster_encryption_config        = null
    attach_cluster_encryption_policy = false
    kms_key_enable_default_policy    = true

    vpc_id                   = module.vpc.vpc_id
    subnet_ids               = module.vpc.private_subnets
    control_plane_subnet_ids = module.vpc.public_subnets

    eks_managed_node_group_defaults = {
      disk_size = 8
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/${local.iam.ebs_csi_irsa_role_name}"
      }
    }

    eks_managed_node_groups = {
      general = {
        name                            = "nodegroup-${local.name_suffix}"
        use_name_prefix                 = false
        desired_size                    = 3
        min_size                        = 2
        max_size                        = 3
        force_update_version            = true
        launch_template_name            = "launch-template-${local.name_suffix}"
        launch_template_use_name_prefix = false
        launch_template_tags = {
          Name = "launch-template-${local.name_suffix}"
        }
        iam_role_name            = "node-role-${local.name_suffix}"
        iam_role_use_name_prefix = false
        iam_role_tags = {
          Name = "node-role-${local.name_suffix}"
        }

        instance_types = ["t3.large"]
        capacity_type  = "ON_DEMAND"

        tags = merge(local.tags, {
          Name = "nodegroup-${local.name_suffix}"
        })

        iam_role_additional_policies = {
          AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
          AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
          AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
          AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
          AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/${local.iam.ebs_csi_irsa_role_name}"
        }
      }
    }
  }

  readiness = {
    kong_load_balancer_wait = "90s"
    # CRDs need a moment to register before ClusterIssuer resources can land
    cert_manager_crd_wait      = "30s"
    gitlab_timeout_seconds     = 1800
    jenkins_timeout_seconds    = 900
    nexus_timeout_seconds      = 900
    prometheus_timeout_seconds = 1200
  }

  helm_releases = {
    kong = {
      chart            = "kong"
      name             = "kong"
      repository       = "https://charts.konghq.com"
      chart_version    = "3.2.0"
      namespace        = "kong"
      create_namespace = true

      sets = concat(
        [
          { name = "proxy.stream[0].containerPort", value = "22" },
          { name = "proxy.stream[0].servicePort", value = "22" },
          { name = "proxy.stream[0].protocol", value = "TCP" },
          # filterSecrets stops Kong's webhook from intercepting cert-manager TLS secrets
          { name = "ingressController.admissionWebhook.filterSecrets", value = "true" },
          { name = "manager.enabled", value = "false" },
          { name = "portal.enabled", value = "false" },
          { name = "portalapi.enabled", value = "false" },
          { name = "proxy.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type", value = "nlb", type = "string" },
        ],
        [for i, cidr in var.allowed_cidrs : {
          name  = "proxy.loadBalancerSourceRanges[${i}]"
          value = cidr
        }]
      )
    }

    cert_manager = {
      chart            = "cert-manager"
      name             = "cert-manager"
      repository       = "https://charts.jetstack.io"
      chart_version    = "1.19.2"
      namespace        = "cert-manager"
      create_namespace = true

      sets = [
        { name = "crds.enabled", value = "true" },
      ]
    }

    kube_prometheus_stack = {
      chart            = "kube-prometheus-stack"
      name             = "kube-prometheus-stack"
      repository       = "https://prometheus-community.github.io/helm-charts"
      chart_version    = "77.12.0"
      namespace        = "monitoring"
      create_namespace = true

      sets = [
        { name = "grafana.ingress.enabled", value = "true" },
        { name = "grafana.ingress.ingressClassName", value = "kong" },
        { name = "grafana.ingress.hosts[0]", value = "grafana.${local.fqdn}" },
        { name = "grafana.ingress.tls[0].secretName", value = "grafana-tls" },
        { name = "grafana.ingress.tls[0].hosts[0]", value = "grafana.${local.fqdn}" },
        { name = "grafana.ingress.annotations.cert-manager\\.io/cluster-issuer", value = "letsencrypt-prod", type = "string" },

        { name = "grafana.persistence.enabled", value = "true" },
        { name = "grafana.persistence.type", value = "pvc" },
        { name = "grafana.persistence.storageClassName", value = local.monitoring.storage_class },
        { name = "grafana.persistence.accessModes[0]", value = "ReadWriteOnce" },
        { name = "grafana.persistence.size", value = local.monitoring.grafana_storage_size },
        { name = "grafana.persistence.finalizers[0]", value = "kubernetes.io/pvc-protection" },
        { name = "prometheus.ingress.enabled", value = "false" },
        { name = "prometheus.prometheusSpec.retention", value = local.monitoring.prometheus_retention },
        { name = "prometheus.prometheusSpec.retentionSize", value = local.monitoring.prometheus_retention_size },
        { name = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName", value = local.monitoring.storage_class },
        { name = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]", value = "ReadWriteOnce" },
        { name = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage", value = local.monitoring.prometheus_storage_size },
      ]

      wait          = true
      wait_for_jobs = true
      timeout       = local.readiness.prometheus_timeout_seconds
    }


    gitlab = {
      chart            = "gitlab"
      name             = "gitlab"
      repository       = "https://charts.gitlab.io/"
      chart_version    = "9.10.0"
      namespace        = "gitlab"
      create_namespace = true

      sets = [
        { name = "global.edition", value = "ce" },
        { name = "global.hosts.domain", value = local.fqdn },
        { name = "global.ingress.tls.enabled", value = "true" },
        { name = "gitlab.gitaly.persistence.size", value = "10Gi" },
        { name = "global.ingress.enabled", value = "true" },
        # kong ingress instead of bundled nginx
        { name = "global.ingress.class", value = "kong" },
        { name = "global.ingress.provider", value = "kong" },
        { name = "global.ingress.configureCertmanager", value = "true" },
        { name = "global.kas.enabled", value = "false" },
        { name = "global.appConfig.gitlab_kas.enabled", value = "false" },
        { name = "gitlab.webservice.ingress.tls.secretName", value = "webservice-tls" },
        { name = "minio.ingress.tls.secretName", value = "minio-tls" },
        { name = "nginx-ingress.enabled", value = "false" },
        # cert-manager is managed externally
        { name = "installCertmanager", value = "false" },
        { name = "certmanager.installCRDs", value = "false" },
        { name = "certmanager-issuer.email", value = local.acme_email },
        { name = "certmanager-issuer.server", value = "https://acme-v02.api.letsencrypt.org/directory" },
        { name = "prometheus.install", value = "false" },
        { name = "global.registry.enabled", value = "false" },
        { name = "registry.enabled", value = "false" },
        # runner off by default
        { name = "gitlab-runner.install", value = "false" }
      ]
      wait          = true
      wait_for_jobs = true
      timeout       = local.readiness.gitlab_timeout_seconds
    }

    jenkins = {
      chart            = "jenkins"
      name             = "jenkins"
      repository       = "https://charts.jenkins.io"
      chart_version    = "5.9.10"
      namespace        = "jenkins"
      create_namespace = true

      sets = [
        { name = "controller.ingress.enabled", value = "true" },
        { name = "controller.ingress.hostName", value = "jenkins.${local.fqdn}" },
        { name = "controller.ingress.tls[0].secretName", value = "jenkins-tls" },
        { name = "controller.ingress.tls[0].hosts[0]", value = "jenkins.${local.fqdn}" },
        { name = "controller.ingress.annotations.cert-manager\\.io/cluster-issuer", value = "letsencrypt-prod" },
        { name = "controller.ingress.ingressClassName", value = "kong" },
        { name = "controller.installLatestPlugins", value = "false" },
      ]
      wait    = true
      timeout = local.readiness.jenkins_timeout_seconds
    }

    nexus = {
      chart            = "nexus-repository-manager"
      name             = "nexus"
      repository       = "https://sonatype.github.io/helm3-charts/"
      chart_version    = "64.2.0"
      namespace        = "nexus"
      create_namespace = true

      sets = [
        { name = "image.tag", value = "3.80.0" },
        { name = "ingress.enabled", value = "true" },
        { name = "ingress.ingressClassName", value = "kong" },
        { name = "ingress.annotations.cert-manager\\.io/cluster-issuer", value = "letsencrypt-prod", type = "string" },
        { name = "ingress.annotations.ingress\\.kubernetes\\.io/force-ssl-redirect", value = "true", type = "string" },
        { name = "ingress.annotations.konghq\\.com/https-redirect-status-code", value = "308", type = "string" },
        { name = "ingress.annotations.konghq\\.com/strip-path", value = "false", type = "string" },
        { name = "ingress.hostRepo", value = "nexus.${local.fqdn}" },
        { name = "ingress.hostPath", value = "/" },
        { name = "ingress.tls[0].secretName", value = "nexus-tls" },
        { name = "ingress.tls[0].hosts[0]", value = "nexus.${local.fqdn}" },
        { name = "nexus.docker.enabled", value = "true" },
        { name = "nexus.docker.registries[0].host", value = "docker.nexus.${local.fqdn}" },
        # Kong terminates TLS; connector stays on internal port 5000
        { name = "nexus.docker.registries[0].port", value = "5000" },
        { name = "nexus.docker.registries[0].secretName", value = "nexus-docker-tls" },
      ]
      wait          = true
      wait_for_jobs = true
      timeout       = local.readiness.nexus_timeout_seconds
    }
  }

  route53 = {
    zone_name           = local.domain
    gitlab_name         = "gitlab.${local.fqdn}"
    nexus_record        = "nexus.${local.fqdn}"
    nexus_docker_record = "docker.nexus.${local.fqdn}"
    jenkins_record      = "jenkins.${local.fqdn}"
    minio_record        = "minio.${local.fqdn}"
    grafana_record      = "grafana.${local.fqdn}"
    records             = [data.aws_lb.kong_proxy.dns_name]
  }

  k8s = {
    proxy = {
      service_name = "kong-kong-proxy"
      namespace    = local.helm_releases.kong.namespace
    }
  }
}
