resource "kubectl_manifest" "terminated_pod_gc_service_account" {
  # EKS doesn't expose kube-controller-manager flags, so we clean up terminal pods manually
  yaml_body = file("${path.module}/manifests/terminated-pod-gc-service-account.yaml")

  depends_on = [module.eks]
}

resource "kubectl_manifest" "terminated_pod_gc_cluster_role" {
  yaml_body = file("${path.module}/manifests/terminated-pod-gc-cluster-role.yaml")

  depends_on = [module.eks]
}

resource "kubectl_manifest" "terminated_pod_gc_cluster_role_binding" {
  yaml_body = file("${path.module}/manifests/terminated-pod-gc-cluster-role-binding.yaml")

  depends_on = [
    kubectl_manifest.terminated_pod_gc_service_account,
    kubectl_manifest.terminated_pod_gc_cluster_role,
  ]
}

resource "kubectl_manifest" "terminated_pod_gc_cronjob" {
  yaml_body = file("${path.module}/manifests/terminated-pod-gc-cronjob.yaml")

  depends_on = [kubectl_manifest.terminated_pod_gc_cluster_role_binding]
}