data "aws_route53_zone" "selected" {
  name         = var.zone_name
  private_zone = false
}

# Every record in this module points at the same Kong load balancer hostname.
# Host-based routing is handled inside the cluster by the ingress controller.
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.gitlab_name
  type    = "CNAME"
  ttl     = 300
  records = var.records
}

resource "aws_route53_record" "nexus_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.nexus_record
  type    = "CNAME"
  ttl     = 300
  records = var.records
}

resource "aws_route53_record" "nexus_docker_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.nexus_docker_record
  type    = "CNAME"
  ttl     = 300
  records = var.records
}

resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.jenkins_record
  type    = "CNAME"
  ttl     = 300
  records = var.records
}

resource "aws_route53_record" "minio_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.minio_record
  type    = "CNAME"
  ttl     = 300
  records = var.records
}

resource "aws_route53_record" "grafana_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.grafana_record
  type    = "CNAME"
  ttl     = 300
  records = var.records
}
