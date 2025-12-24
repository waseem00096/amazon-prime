data "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  
  # Allow the name to be adopted if it exists
  force_update = true

  set = [
    {
      name  = "args"
      value = "{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}"
    }
  ]
}

resource "helm_release" "prometheus_stack" {
  name       = "kube-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = data.kubernetes_namespace_v1.monitoring.metadata[0].name

  # CRITICAL: Increase timeout to 15 minutes for bare-metal
  timeout         = 900 
  force_update    = true
  cleanup_on_fail = true
  atomic          = false # Don't rollback immediately on one small error

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
