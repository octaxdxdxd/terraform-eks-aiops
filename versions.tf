terraform {
  required_version = "~>1.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~>2.17.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.00.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
