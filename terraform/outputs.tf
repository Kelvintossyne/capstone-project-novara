output "vpc_id" {
  description = "VPC ID — needed for kops/cluster.yaml networkID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Paste into kops/cluster.yaml subnets[].id"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "Paste into kops/cluster.yaml subnets[].egress"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  value = module.vpc.nat_gateway_public_ips
}

output "availability_zones" {
  value = module.vpc.availability_zones
}

output "s3_kops_bucket_name" {
  description = "Set KOPS_STATE_STORE=s3://<this value>"
  value       = module.s3.kops_bucket_name
}

output "s3_terraform_bucket_name" {
  value = module.s3.terraform_bucket_name
}

output "s3_etcd_backup_bucket_name" {
  value = module.s3.etcd_backup_bucket_name
}

output "iam_cluster_creator_arn" {
  value = module.iam.cluster_creator_arn
}

output "iam_cluster_operator_arn" {
  value = module.iam.cluster_operator_arn
}

output "kops_master_instance_profile" {
  description = "Paste into kops cluster spec as master instanceProfile"
  value       = module.iam.kops_master_profile_name
}

output "kops_worker_instance_profile" {
  description = "Paste into kops cluster spec as worker instanceProfile"
  value       = module.iam.kops_worker_profile_name
}

output "route53_zone_id" {
  value = module.dns.zone_id
}

output "route53_name_servers" {
  description = "Set these 4 NS records at your domain registrar"
  value       = module.dns.name_servers
}

output "k8s_zone_id" {
  description = "Paste into kops/cluster.yaml as dnsZone"
  value       = module.dns.k8s_zone_id
}

output "dynamodb_lock_table" {
  value = aws_dynamodb_table.terraform_locks.name
}

output "taskapp_url" {
  value = module.dns.taskapp_fqdn
}

output "api_url" {
  value = module.dns.api_fqdn
}
