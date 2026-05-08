variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "create_cloudwatch_log_group" {
  type = bool
}

variable "enable_irsa" {
  type = bool
}

variable "cluster_endpoint_private_access" {
  type = bool
}

variable "cluster_endpoint_public_access" {
  type = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  type = list(string)
}

variable "cluster_addons" {
  type = any
}

variable "enable_cluster_creator_admin_permissions" {
  type = bool
}

variable "create_kms_key" {
  type = bool
}

variable "enable_kms_key_rotation" {
  type = bool
}

variable "cluster_encryption_config" {
  type    = any
  default = {}
}

variable "attach_cluster_encryption_policy" {
  type = bool
}

variable "kms_key_enable_default_policy" {
  type = bool
}

variable "iam_role_name" {
  type    = string
  default = null
}

variable "iam_role_use_name_prefix" {
  type    = bool
  default = true
}

variable "security_group_name" {
  type    = string
  default = null
}

variable "security_group_use_name_prefix" {
  type    = bool
  default = true
}

variable "node_security_group_name" {
  type    = string
  default = null
}

variable "node_security_group_use_name_prefix" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "control_plane_subnet_ids" {
  type = list(string)
}

variable "eks_managed_node_group_defaults" {
  type = any
}

variable "eks_managed_node_groups" {
  type = any
}

variable "tags" {
  type    = map(string)
  default = {}
}
