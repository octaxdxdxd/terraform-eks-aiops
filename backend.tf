# State is stored under the configured key.
# When using Terraform workspaces, non-default workspaces are automatically
# isolated at env:/<workspace>/terraform/terraform.tfstate within the same bucket.
terraform {
  backend "s3" {
    bucket       = "tfstate-bucket-testing123"
    key          = "terraform/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}