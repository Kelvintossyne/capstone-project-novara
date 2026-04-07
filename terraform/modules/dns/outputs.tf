output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Name servers - add these to your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "taskapp_fqdn" {
  description = "Frontend URL"
  value       = "https://taskapp.${var.domain_name}"
}

output "api_fqdn" {
  description = "Backend API URL"
  value       = "https://api.${var.domain_name}"
}
