variable "aws_account_id" {
  type        = string
  description = "AWS account ID used to construct IAM role ARNs"
}

variable "devops_agent_role_name" {
  type        = string
  description = "Name of the IAM role used by the DevOps agent (without path prefix)"
}


variable "domain" {
  type        = string
  description = "Root Route53 hosted zone domain (e.g. example.com)"
}

variable "acme_email" {
  type        = string
  description = "Email address for Let's Encrypt ACME certificate registration"
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "CIDR ranges allowed to reach the EKS API endpoint and Kong load balancer"
  default     = []
}

variable "name_suffix" {
  type        = string
  description = "Suffix appended to all AWS resource names to distinguish environments (e.g. project-dev, project-prod)"
}

variable "env_subdomain" {
  type        = string
  description = "Subdomain prefix for this environment (e.g. 'dev' → nexus.dev.example.com). Leave empty for prod (nexus.example.com)."
  default     = ""
}
