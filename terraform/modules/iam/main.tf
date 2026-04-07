# ─── Cluster Creator Role ───────────────────────────────────────────────────
# Used only for initial cluster creation - has broad permissions
resource "aws_iam_role" "cluster_creator" {
  name = "${var.project_name}-cluster-creator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-cluster-creator-role"
  }
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

# ─── Cluster Operator Role ───────────────────────────────────────────────────
# Used for day-to-day cluster operations - least privilege
resource "aws_iam_role" "cluster_operator" {
  name = "${var.project_name}-cluster-operator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-cluster-operator-role"
  }
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
          "ec2:Describe*",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "autoscaling:Describe*",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-kops-state-*",
          "arn:aws:s3:::${var.project_name}-kops-state-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:GetHostedZone"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "operator_policy" {
  role       = aws_iam_role.cluster_operator.name
  policy_arn = aws_iam_policy.cluster_operator_policy.arn
}

# ─── Instance Profiles ───────────────────────────────────────────────────────
resource "aws_iam_instance_profile" "cluster_creator" {
  name = "${var.project_name}-cluster-creator-profile"
  role = aws_iam_role.cluster_creator.name
}

resource "aws_iam_instance_profile" "cluster_operator" {
  name = "${var.project_name}-cluster-operator-profile"
  role = aws_iam_role.cluster_operator.name
}
