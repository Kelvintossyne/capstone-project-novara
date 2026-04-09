terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_zone" "k8s" {
  name = "k8s.${var.domain_name}"
}
