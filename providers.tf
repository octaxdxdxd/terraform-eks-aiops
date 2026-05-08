provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Owner     = "Octavian Popov"
      Purpose   = "Terraform EKS Demo"
      Terraform = "True"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_url
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "kubectl" {
  config_path            = "~/.kube/config"
  apply_retry_count      = 15
  host                   = module.eks.cluster_url
  cluster_ca_certificate = base64decode(module.eks.cluster_ca)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_url
    cluster_ca_certificate = base64decode(module.eks.cluster_ca)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}
