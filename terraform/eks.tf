module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "shodapp-cluster"
  cluster_version = "1.31"
  cluster_service_ipv4_cidr = "10.200.0.0/16"
  cluster_endpoint_public_access  = true


  # Disable creation of security groups
  create_cluster_security_group = false
  create_node_security_group    = false
  cluster_security_group_id = aws_security_group.Allow_services.id
  enable_irsa = true

  
  cluster_addons = {
    coredns                = {} # coredns its for manage the dns server
    eks-pod-identity-agent = {} # eks-pod-identity-agent its for manage the pod identity
    kube-proxy             = {} # kube-proxy its for manage the kube-proxy
    vpc-cni                = {} # vpc cni its for manage the network and associate IPs to pods
    aws-ebs-csi-driver     = {} # aws ebs csi driver its for manage the ebs csi driver
  }

    vpc_id                   =  module.vpc.vpc_id
    subnet_ids               = [
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
    iam_role_name =  aws_iam_role.eks_cluster_role.name
    iam_role_arn  =  aws_iam_role.eks_cluster_role.arn
  }

  eks_managed_node_groups = {
    shodan-k8s = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.large"]

      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size
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
    DB_USER         = "postgres"
    DB_PASSWORD     = var.db_password
    DB_HOST = replace(aws_db_instance.postgres.endpoint, ":5432", "")
    DB_NAME         = "postgres"
    JWT_SECRET_KEY  = var.JWT_SECRET_KEY
    SHODAN_API_KEY  = var.SHODAN_API_KEY
    REACT_APP_API_URL = "https://shodapp.seansalmassi.com/api"
  }

  depends_on = [
    kubernetes_namespace.shodapp,
    aws_db_instance.postgres
  ]
}

resource "kubernetes_ingress_v1" "shodapp" {
  metadata {
    name      = "shodapp-ingress"
    namespace = "shodapp"
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{"HTTPS": 443}, {"HTTP": 80}])
      "alb.ingress.kubernetes.io/certificate-arn" = module.acm.acm_certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      "alb.ingress.kubernetes.io/group.name" = "shodapp"
      "alb.ingress.kubernetes.io/group.order" = "1"
      "alb.ingress.kubernetes.io/target-group-attributes" = "stickiness.enabled=true,stickiness.type=lb_cookie"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/success-codes" = "200-399"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = "10"
      "alb.ingress.kubernetes.io/healthy-threshold-count" = "2"
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" = "2"
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "idle_timeout.timeout_seconds=60,routing.http2.enabled=true"
    }
  }

  spec {
    rule {
      host = "shodapp.seansalmassi.com"
      http {
        path {
          path = "/api/*"
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
          path = "/*"
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
          path = "/metrics"
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