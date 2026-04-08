output "kops_bucket_name" {
  description = "S3 bucket name for Kops state store"
  value       = aws_s3_bucket.kops_state.id
}

output "kops_bucket_arn" {
  description = "S3 bucket ARN for Kops state store"
  value       = aws_s3_bucket.kops_state.arn
}

output "terraform_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_bucket_arn" {
  description = "S3 bucket ARN for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "etcd_backup_bucket_name" {
  description = "S3 bucket name for etcd backups"
  value       = aws_s3_bucket.etcd_backups.id
}

output "etcd_backup_bucket_arn" {
  description = "S3 bucket ARN for etcd backups"
  value       = aws_s3_bucket.etcd_backups.arn
}
