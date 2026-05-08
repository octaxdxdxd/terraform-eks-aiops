variable "tags" {
  type    = map(string)
  default = {}
}

variable "security_group_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}