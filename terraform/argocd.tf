# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false  # We create the namespace separately
  version          = "4.5.2"

  values = [
    <<-EOT
    server:
      extraArgs:
        - --insecure # Disable TLS on the server
      service:
        type: ClusterIP
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: alb
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}, {"HTTP": 80}]'
          alb.ingress.kubernetes.io/certificate-arn: ${module.acm.acm_certificate_arn}
          alb.ingress.kubernetes.io/ssl-redirect: "443"
          alb.ingress.kubernetes.io/backend-protocol: HTTP
          alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
          alb.ingress.kubernetes.io/healthcheck-port: traffic-port
          alb.ingress.kubernetes.io/healthcheck-path: /healthz
          alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
          alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
          alb.ingress.kubernetes.io/healthy-threshold-count: "2"
          alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
          alb.ingress.kubernetes.io/group.name: argocd
        hosts:
          - argocd.shodapp.seansalmassi.com
        paths:
          - /*
        pathType: ImplementationSpecific

    configs:
      params:
        server.insecure: true
      
    redis:
      enabled: true

    controller:
      enableStatefulSet: true
    EOT
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.aws_load_balancer_controller
  ]
}

# Get the ALB DNS name for ArgoCD
data "aws_lb" "argocd" {
  tags = {
    "elbv2.k8s.aws/cluster" = module.eks.cluster_name
    "ingress.k8s.aws/stack" = "argocd"
  }

  depends_on = [
    helm_release.argocd,
    time_sleep.wait_for_argocd_alb
  ]
}

# Add a delay to wait for ALB creation
resource "time_sleep" "wait_for_argocd_alb" {
  depends_on = [helm_release.argocd]
  create_duration = "30s"
}

# Create Route53 record for ArgoCD
resource "aws_route53_record" "argocd" {
  provider = aws.personal
  zone_id  = var.zone_id
  name     = "argocd.shodapp.seansalmassi.com"
  type     = "A"

  alias {
    name                   = data.aws_lb.argocd.dns_name
    zone_id                = data.aws_lb.argocd.zone_id
    evaluate_target_health = true
  }

  depends_on = [
    helm_release.argocd,
    data.aws_lb.argocd
  ]
}