output "cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_url" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_arn" {
  value = module.eks.oidc_provider_arn

}

output "eks_managed_node_groups_autoscaling_group_name" {
  value = module.eks.eks_managed_node_groups_autoscaling_group_names
}
