output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs across 3 AZs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs across 3 AZs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (one per AZ)"
  value       = module.vpc.nat_gateway_ids
}

output "s3_kops_bucket_name" {
  description = "S3 bucket name for kops state"
  value       = module.s3.kops_bucket_name
}

output "s3_terraform_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = module.s3.terraform_bucket_name
}

output "iam_cluster_creator_arn" {
  description = "IAM role ARN for cluster creation"
  value       = module.iam.cluster_creator_arn
}

output "iam_cluster_operator_arn" {
  description = "IAM role ARN for cluster operations"
  value       = module.iam.cluster_operator_arn
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.dns.zone_id
}

output "route53_name_servers" {
  description = "Name servers to delegate from your registrar"
  value       = module.dns.name_servers
}

output "dynamodb_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}
