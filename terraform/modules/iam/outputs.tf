output "cluster_creator_arn" {
  description = "IAM role ARN for cluster creation"
  value       = aws_iam_role.cluster_creator.arn
}

output "cluster_operator_arn" {
  description = "IAM role ARN for cluster operations"
  value       = aws_iam_role.cluster_operator.arn
}

output "cluster_creator_profile" {
  description = "Instance profile for cluster creator"
  value       = aws_iam_instance_profile.cluster_creator.name
}

output "cluster_operator_profile" {
  description = "Instance profile for cluster operator"
  value       = aws_iam_instance_profile.cluster_operator.name
}
