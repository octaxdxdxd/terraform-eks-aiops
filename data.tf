resource "time_sleep" "kong_load_balancer" {
  create_duration = local.readiness.kong_load_balancer_wait
  depends_on      = [module.kong]
}

data "aws_lbs" "kong_proxy" {
  tags = {
    "kubernetes.io/service-name"                      = "${local.k8s.proxy.namespace}/${local.k8s.proxy.service_name}"
    "kubernetes.io/cluster/${local.eks.cluster_name}" = "owned"
  }

  depends_on = [time_sleep.kong_load_balancer]
}

data "aws_lb" "kong_proxy" {
  arn = one(data.aws_lbs.kong_proxy.arns)
}
