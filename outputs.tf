output "kong_ingress_hostname" {
  value = data.aws_lb.kong_proxy.dns_name
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_url
}

output "gitlab_url" {
  value = "https://gitlab.${local.fqdn}"
}

output "jenkins_url" {
  value = "https://jenkins.${local.fqdn}"
}

output "nexus_url" {
  value = "https://nexus.${local.fqdn}"
}

output "nexus_docker_registry" {
  value = "docker.nexus.${local.fqdn}"
}

output "grafana_url" {
  value = "https://grafana.${local.fqdn}"
}
