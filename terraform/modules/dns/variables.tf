variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "domain_name" {
  description = "Your registered domain name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "load_balancer_dns" {
  description = "DNS name of the load balancer"
  type        = string
  default     = "placeholder.elb.amazonaws.com"
}
