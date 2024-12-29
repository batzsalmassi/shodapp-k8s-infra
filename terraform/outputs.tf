output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "acm_certificate_arn" {
  value = module.acm.acm_certificate_arn
}

output "argocd_server_url" {
  description = "URL of the ArgoCD server"
  value       = "https://argocd.shodapp.seansalmassi.com"
}
