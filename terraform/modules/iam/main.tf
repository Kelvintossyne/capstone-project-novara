terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
resource "aws_iam_role" "cluster_creator" {
  name = "${var.project_name}-cluster-creator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.project_name}-cluster-creator-role" }
}

resource "aws_iam_role_policy_attachment" "creator_ec2" {
  role       = aws_iam_role.cluster_creator.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "creator_s3" {
  role       = aws_iam_role.cluster_creator.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "creator_route53" {
  role       = aws_iam_role.cluster_creator.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_role_policy_attachment" "creator_iam" {
  role       = aws_iam_role.cluster_creator.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "creator_vpc" {
  role       = aws_iam_role.cluster_creator.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_instance_profile" "cluster_creator" {
  name = "${var.project_name}-cluster-creator-profile"
  role = aws_iam_role.cluster_creator.name
}

resource "aws_iam_role" "cluster_operator" {
  name = "${var.project_name}-cluster-operator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.project_name}-cluster-operator-role" }
}

resource "aws_iam_policy" "cluster_operator_policy" {
  name        = "${var.project_name}-cluster-operator-policy"
  description = "Least privilege policy for cluster operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*", "ec2:AttachVolume", "ec2:DetachVolume",
          "ec2:CreateVolume", "ec2:DeleteVolume",
          "autoscaling:Describe*", "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.project_name}-kops-state-*",
          "arn:aws:s3:::${var.project_name}-kops-state-*/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets", "route53:GetHostedZone"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "operator_policy" {
  role       = aws_iam_role.cluster_operator.name
  policy_arn = aws_iam_policy.cluster_operator_policy.arn
}

resource "aws_iam_instance_profile" "cluster_operator" {
  name = "${var.project_name}-cluster-operator-profile"
  role = aws_iam_role.cluster_operator.name
}

resource "aws_iam_role" "kops_master" {
  name = "${var.project_name}-kops-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.project_name}-kops-master-role" }
}

resource "aws_iam_role_policy" "kops_master" {
  name = "${var.project_name}-kops-master-policy"
  role = aws_iam_role.kops_master.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances", "ec2:DescribeRegions", "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications", "ec2:DescribeInstanceTypes", "ec2:DescribeVpcs",
          "ec2:CreateSecurityGroup", "ec2:CreateTags", "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute", "ec2:ModifyVolume",
          "ec2:AttachVolume", "ec2:DetachVolume", "ec2:DeleteVolume",
          "ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELB"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:AttachLoadBalancerToSubnets",
          "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateLoadBalancerPolicy",
          "elasticloadbalancing:CreateLoadBalancerListeners",
          "elasticloadbalancing:ConfigureHealthCheck",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancerListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DetachLoadBalancerFromSubnets",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:RegisterTargets"
        ]
        Resource = "*"
      },
      {
        Sid      = "Route53"
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets", "route53:GetHostedZone", "route53:ListHostedZones"]
        Resource = "*"
      },
      {
        Sid      = "S3List"
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation", "s3:GetEncryptionConfiguration", "s3:ListBucket", "s3:ListBucketVersions"]
        Resource = ["arn:aws:s3:::${var.project_name}-kops-state-*", "arn:aws:s3:::${var.project_name}-etcd-backups-*"]
      },
      {
        Sid      = "S3Objects"
        Effect   = "Allow"
        Action   = ["s3:Get*", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::${var.project_name}-kops-state-*/*", "arn:aws:s3:::${var.project_name}-etcd-backups-*/*"]
      },
      {
        Sid      = "ECR"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kops_master" {
  name = "${var.project_name}-kops-master-profile"
  role = aws_iam_role.kops_master.name

  tags = { Name = "${var.project_name}-kops-master-profile" }
}

resource "aws_iam_role" "kops_worker" {
  name = "${var.project_name}-kops-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.project_name}-kops-worker-role" }
}

resource "aws_iam_role_policy" "kops_worker" {
  name = "${var.project_name}-kops-worker-policy"
  role = aws_iam_role.kops_worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances", "ec2:DescribeRegions", "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVolumes",
          "ec2:DescribeInstanceTypes", "ec2:AttachVolume", "ec2:DetachVolume", "ec2:CreateTags"
        ]
        Resource = "*"
      },
      {
        Sid      = "S3StateRead"
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation", "s3:ListBucket", "s3:Get*"]
        Resource = ["arn:aws:s3:::${var.project_name}-kops-state-*", "arn:aws:s3:::${var.project_name}-kops-state-*/*"]
      },
      {
        Sid      = "ECR"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kops_worker" {
  name = "${var.project_name}-kops-worker-profile"
  role = aws_iam_role.kops_worker.name

  tags = { Name = "${var.project_name}-kops-worker-profile" }
}
