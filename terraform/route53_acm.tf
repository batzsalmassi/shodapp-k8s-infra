# ACM Certificate in CloudGuru (sandbox) Account
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name            = "shodapp.seansalmassi.com"
  validation_method      = "DNS"
  create_route53_records = false # We are manually creating DNS records in the personal account

  tags = {
    Name = "shodapp.seansalmassi.com"
  }
}

# Create DNS validation CNAME record in Personal Account's Route 53
resource "aws_route53_record" "acm_validation" {
  provider = aws.personal # Use the personal account provider alias
  for_each = {
    for dvo in module.acm.acm_certificate_domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.zone_id # Hosted zone ID of your personal domain
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Validate the certificate
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = module.acm.acm_certificate_arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# Get the ALB DNS name
data "aws_lb" "ingress" {
  tags = {
    "elbv2.k8s.aws/cluster" = module.eks.cluster_name
    "ingress.k8s.aws/stack" = "shodapp"
  }

  depends_on = [
    kubernetes_ingress_v1.shodapp,
    # Wait a bit for the ALB to be created
    time_sleep.wait_for_alb
  ]
}

# Add a delay to wait for ALB creation
resource "time_sleep" "wait_for_alb" {
  depends_on = [kubernetes_ingress_v1.shodapp]
  create_duration = "30s"
}

# Create A record in Personal Account after successful ACM validation
resource "aws_route53_record" "seansalmassi-com" {
  provider = aws.personal
  zone_id  = var.zone_id

  name = "shodapp.seansalmassi.com"
  type = "A"

  alias {
    name                   = data.aws_lb.ingress.dns_name
    zone_id                = data.aws_lb.ingress.zone_id
    evaluate_target_health = true
  }

  depends_on = [helm_release.aws_load_balancer_controller, aws_acm_certificate_validation.cert]
}