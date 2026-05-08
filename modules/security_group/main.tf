module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.1"

  name        = var.security_group_name
  description = "Complete PostgreSQL example security group"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from corporate VPN IPs"
      cidr_blocks = "130.41.21.10/32,130.41.21.100/32,130.41.21.102/32,130.41.21.103/32,130.41.21.105/32,130.41.21.101/32,130.41.21.104/32,130.41.21.106/32,208.127.135.162/32,208.127.135.161/32"
    }
  ]

  tags = var.tags
}