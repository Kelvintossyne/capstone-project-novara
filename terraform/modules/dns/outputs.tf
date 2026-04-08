output "zone_id" {
  description = "Route53 hosted zone ID for root domain"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "NS records to set at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "k8s_zone_id" {
  description = "Route53 zone ID for k8s subdomain"
  value       = aws_route53_zone.k8s.zone_id
}

output "k8s_zone_name_servers" {
  description = "NS records for k8s subdomain"
  value       = aws_route53_zone.k8s.name_servers
}

output "taskapp_fqdn" {
  description = "Frontend URL"
  value       = "https://taskapp.${var.domain_name}"
}

output "api_fqdn" {
  description = "Backend API URL"
  value       = "https://api.${var.domain_name}"
}
