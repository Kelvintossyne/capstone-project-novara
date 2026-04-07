# ─── Route53 Hosted Zone ─────────────────────────────────────────────────────
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = "${var.project_name}-zone"
    Environment = var.environment
  }
}

# ─── Taskapp Subdomain ───────────────────────────────────────────────────────
resource "aws_route53_record" "taskapp" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "taskapp.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.load_balancer_dns]

  lifecycle {
    ignore_changes = [records]
  }
}

# ─── API Subdomain ───────────────────────────────────────────────────────────
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.load_balancer_dns]

  lifecycle {
    ignore_changes = [records]
  }
}

# ─── Kubernetes API Subdomain ─────────────────────────────────────────────────
resource "aws_route53_record" "k8s_api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.taskapp.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.load_balancer_dns]

  lifecycle {
    ignore_changes = [records]
  }
}
