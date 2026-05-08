module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.1"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  create_cloudwatch_log_group = var.create_cloudwatch_log_group

  enable_irsa = var.enable_irsa

  endpoint_private_access      = var.cluster_endpoint_private_access
  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  addons = var.cluster_addons

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  create_kms_key                      = var.create_kms_key
  enable_kms_key_rotation             = var.enable_kms_key_rotation
  encryption_config                   = var.cluster_encryption_config
  attach_encryption_policy            = var.attach_cluster_encryption_policy
  kms_key_enable_default_policy       = var.kms_key_enable_default_policy
  iam_role_name                       = var.iam_role_name
  iam_role_use_name_prefix            = var.iam_role_use_name_prefix
  security_group_name                 = var.security_group_name
  security_group_use_name_prefix      = var.security_group_use_name_prefix
  node_security_group_name            = var.node_security_group_name
  node_security_group_use_name_prefix = var.node_security_group_use_name_prefix

  vpc_id = var.vpc_id

  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  eks_managed_node_groups = {
    for name, group in var.eks_managed_node_groups :
    name => merge(var.eks_managed_node_group_defaults, group)
  }
  tags = var.tags
}
