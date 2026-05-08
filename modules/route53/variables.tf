variable "zone_name" {
  type        = string
  description = "The Route53 hosted zone domain name (e.g. your-domain.com)"
}

variable "gitlab_name" {
  type = string
}

variable "records" {
  type = list(string)
}

variable "nexus_record" {
  type = string

}

variable "nexus_docker_record" {
  type = string
}

variable "jenkins_record" {
  type = string
}

variable "minio_record" {
  type = string
}

variable "grafana_record" {
  type = string
}
