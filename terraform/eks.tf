module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = "shodapp-cluster"
  cluster_version                = "1.31"
  cluster_service_ipv4_cidr      = "10.200.0.0/16"
  cluster_endpoint_public_access = true


  # Disable creation of security groups
  create_cluster_security_group = false
  create_node_security_group    = false
  cluster_security_group_id     = aws_security_group.Allow_services.id
  enable_irsa                   = true


  cluster_addons = {
    coredns                = {} # coredns its for manage the dns server
    eks-pod-identity-agent = {} # eks-pod-identity-agent its for manage the pod identity
    kube-proxy             = {} # kube-proxy its for manage the kube-proxy
    vpc-cni                = {} # vpc cni its for manage the network and associate IPs to pods
    aws-ebs-csi-driver     = {} # aws ebs csi driver its for manage the ebs csi driver
  }

  vpc_id = module.vpc.vpc_id
  subnet_ids = [
    module.vpc.public_subnets[0],
    module.vpc.public_subnets[1]
  ]
  control_plane_subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]

  # EKS Managed Node Group(s) 
  eks_managed_node_group_defaults = {
    instance_types = ["m5.large"]

    # create self iam role and give access to node group
    create_iam_role = false
    iam_role_name   = aws_iam_role.eks_cluster_role.name
    iam_role_arn    = aws_iam_role.eks_cluster_role.arn
  }

  eks_managed_node_groups = {
    shodan-k8s = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.large"]

      min_size               = var.eks_node_min_size
      max_size               = var.eks_node_max_size
      desired_size           = var.eks_node_desired_size
      vpc_security_group_ids = [aws_security_group.Allow_services.id]
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true


  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "kubernetes_namespace" "shodapp" {
  metadata {
    name = "shodapp"
  }
}

resource "kubernetes_config_map" "shodapp" {
  metadata {
    name      = "shodapp-config"
    namespace = "shodapp"
  }

  data = {
    DB_USER           = "postgres"
    DB_PASSWORD       = var.db_password
    DB_HOST           = replace(aws_db_instance.postgres.endpoint, ":5432", "")
    DB_NAME           = "postgres"
    JWT_SECRET_KEY    = var.JWT_SECRET_KEY
    SHODAN_API_KEY    = var.SHODAN_API_KEY
    REACT_APP_API_URL = "https://shodapp.seansalmassi.com/api"
  }

  depends_on = [
    kubernetes_namespace.shodapp,
    aws_db_instance.postgres
  ]
}

# This resource block defines a Kubernetes Ingress resource for the "shodapp" application.
# The Ingress resource is used to manage external access to the services within the Kubernetes cluster.

# Metadata section:
# - name: The name of the Ingress resource.
# - namespace: The namespace where the Ingress resource will be created.
# - annotations: A set of key-value pairs to configure the behavior of the AWS Application Load Balancer (ALB).

# Annotations:
# - kubernetes.io/ingress.class: Specifies that the Ingress resource should use the ALB ingress controller.
# - alb.ingress.kubernetes.io/scheme: Sets the ALB scheme to "internet-facing" for public access.
# - alb.ingress.kubernetes.io/target-type: Specifies that the ALB should target IP addresses.
# - alb.ingress.kubernetes.io/listen-ports: Configures the ALB to listen on ports 80 (HTTP) and 443 (HTTPS).
# - alb.ingress.kubernetes.io/certificate-arn: Specifies the ARN of the ACM certificate for HTTPS.
# - alb.ingress.kubernetes.io/ssl-redirect: Redirects HTTP traffic to HTTPS on port 443.
# - alb.ingress.kubernetes.io/group.name: Groups multiple Ingress resources under the name "shodapp".
# - alb.ingress.kubernetes.io/group.order: Sets the order of the Ingress resource within the group.
# - alb.ingress.kubernetes.io/target-group-attributes: Enables stickiness with load balancer cookies.
# - alb.ingress.kubernetes.io/backend-protocol: Specifies the backend protocol as HTTP.
# - alb.ingress.kubernetes.io/success-codes: Defines the success response codes for health checks.
# - alb.ingress.kubernetes.io/healthcheck-path: Sets the path for health checks.
# - alb.ingress.kubernetes.io/healthcheck-interval-seconds: Interval between health checks.
# - alb.ingress.kubernetes.io/healthcheck-timeout-seconds: Timeout for each health check.
# - alb.ingress.kubernetes.io/healthy-threshold-count: Number of successful health checks before considering the target healthy.
# - alb.ingress.kubernetes.io/unhealthy-threshold-count: Number of failed health checks before considering the target unhealthy.
# - alb.ingress.kubernetes.io/load-balancer-attributes: Configures ALB attributes such as idle timeout and HTTP/2 support.

# Spec section:
# - rule: Defines the routing rules for the Ingress resource.
# - host: Specifies the host for the Ingress resource.
# - http: Defines the HTTP paths and their corresponding backend services.

# Paths:
# - /api/*: Routes API requests to the "shodapp-backend-svc" service on port 5055.
# - /*: Routes all other requests to the "shodapp-frontend-svc" service on port 3000.
# - /metrics: Routes metrics requests to the "shodapp-frontend-svc" service on port 3000.

# Depends_on section:
# - Ensures that the Ingress resource is created after the AWS Load Balancer Controller Helm release and the "shodapp" namespace.
resource "kubernetes_ingress_v1" "shodapp" {
  metadata {
    name      = "shodapp-ingress"
    namespace = "shodapp"
    annotations = {
      "kubernetes.io/ingress.class"                            = "alb"
      "alb.ingress.kubernetes.io/scheme"                       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"                  = "ip"
      "alb.ingress.kubernetes.io/listen-ports"                 = jsonencode([{ "HTTPS" : 443 }, { "HTTP" : 80 }])
      "alb.ingress.kubernetes.io/certificate-arn"              = module.acm.acm_certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect"                 = "443"
      "alb.ingress.kubernetes.io/group.name"                   = "shodapp"
      "alb.ingress.kubernetes.io/group.order"                  = "1"
      "alb.ingress.kubernetes.io/target-group-attributes"      = "stickiness.enabled=true,stickiness.type=lb_cookie"
      "alb.ingress.kubernetes.io/backend-protocol"             = "HTTP"
      "alb.ingress.kubernetes.io/success-codes"                = "200-399"
      "alb.ingress.kubernetes.io/healthcheck-path"             = "/api/health"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "10"
      "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"
      "alb.ingress.kubernetes.io/load-balancer-attributes"     = "idle_timeout.timeout_seconds=60,routing.http2.enabled=true"
    }
  }

  spec {
    rule {
      host = "shodapp.seansalmassi.com"
      http {
        path {
          path      = "/api/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "shodapp-backend-svc"
              port {
                number = 5055
              }
            }
          }
        }
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "shodapp-frontend-svc"
              port {
                number = 3000
              }
            }
          }
        }
        path {
          path      = "/metrics"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "shodapp-frontend-svc"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    kubernetes_namespace.shodapp
  ]
}