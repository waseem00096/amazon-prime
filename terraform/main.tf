# Use 'data' instead of 'resource' if the namespace is already there
data "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus_stack" {
  name       = "kube-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  
  # Point to the data source instead of the resource
  namespace  = data.kubernetes_namespace_v1.monitoring.metadata[0].name

  set = [
    {
      name  = "grafana.service.type"
      value = "NodePort"
    },
    {
      name  = "grafana.service.nodePort"
      value = "32001"
    }
  ]
}
