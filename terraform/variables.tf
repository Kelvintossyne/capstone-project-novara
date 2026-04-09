variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "Must be a valid AWS region format e.g. us-east-1."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "novara"

  validation {
    condition     = length(var.project_name) > 2 && length(var.project_name) < 20
    error_message = "Project name must be between 3 and 20 characters."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development."
  }
}

variable "domain_name" {
  description = "Your registered domain name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]\\.[a-z]{2,}$", var.domain_name))
    error_message = "Must be a valid domain name e.g. yourdomain.com."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Must be a valid CIDR block e.g. 10.0.0.0/16."
  }
}

