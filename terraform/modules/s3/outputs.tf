output "bucket_name" {
  value = aws_s3_bucket.kops_state.id
}

output "bucket_arn" {
  value = aws_s3_bucket.kops_state.arn
}
