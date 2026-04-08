output "cluster_creator_arn" {
  value = aws_iam_role.cluster_creator.arn
}

output "cluster_operator_arn" {
  value = aws_iam_role.cluster_operator.arn
}

output "cluster_creator_profile" {
  value = aws_iam_instance_profile.cluster_creator.name
}

output "cluster_operator_profile" {
  value = aws_iam_instance_profile.cluster_operator.name
}

output "kops_master_profile_name" {
  description = "Instance profile for Kops master nodes — paste into kops cluster spec"
  value       = aws_iam_instance_profile.kops_master.name
}

output "kops_master_role_arn" {
  value = aws_iam_role.kops_master.arn
}

output "kops_worker_profile_name" {
  description = "Instance profile for Kops worker nodes — paste into kops cluster spec"
  value       = aws_iam_instance_profile.kops_worker.name
}

output "kops_worker_role_arn" {
  value = aws_iam_role.kops_worker.arn
}
