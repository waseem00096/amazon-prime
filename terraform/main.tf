# 1. Reference the existing monitoring namespace
data "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# 2. Deploy Metrics Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  # FIX: Added '=' and '[]' to satisfy "Unsupported block type" error
  set = [
    {
      name  = "args"
      value = "{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}"
    }
  ]
}

# 3. Deploy Prometheus/Grafana Stack
resource "helm_release" "prometheus_stack" {
  name       = "kube-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = data.kubernetes_namespace_v1.monitoring.metadata[0].name

  force_update    = true
  cleanup_on_fail = true

  # FIX: Consistent assignment syntax
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
