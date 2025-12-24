# Use _v1 to resolve the deprecation warning
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus_stack" {
  name       = "kube-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  
  # Ensure this reference matches the new v1 resource name
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  set {
    name  = "grafana.service.type"
    value = "NodePort"
  }

  set {
    name  = "grafana.service.nodePort"
    value = "32001"
  }
}
