resource "helm_release" "this" {
  name              = var.name
  repository        = var.repository
  chart             = var.chart
  version           = var.chart_version
  namespace         = var.namespace
  create_namespace  = var.create_namespace
  dependency_update = var.dependency_update
  force_update      = var.force_update
  timeout           = var.timeout

  dynamic "set" {
    for_each = var.sets
    content {
      name  = set.value.name
      value = set.value.value
      type  = try(set.value.type, null)
    }
  }
  wait          = var.wait
  wait_for_jobs = var.wait_for_jobs
}
