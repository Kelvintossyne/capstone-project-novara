terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
resource "aws_s3_bucket" "kops_state" {
  bucket        = "${var.project_name}-kops-state-${var.environment}"
  force_destroy = false

  tags = {
    Name        = "${var.project_name}-kops-state"
    Environment = var.environment
    Purpose     = "kops-state-store"
  }
}

resource "aws_s3_bucket_versioning" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project_name}-terraform-state-${var.environment}"
  force_destroy = false

  tags = {
    Name        = "${var.project_name}-terraform-state"
    Environment = var.environment
    Purpose     = "terraform-state-store"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── etcd Backup Bucket ──────────────────────────────────────────────────────
resource "aws_s3_bucket" "etcd_backups" {
  bucket        = "${var.project_name}-etcd-backups-${var.environment}"
  force_destroy = false

  tags = {
    Name        = "${var.project_name}-etcd-backups"
    Environment = var.environment
    Purpose     = "etcd-automated-backups"
  }
}

resource "aws_s3_bucket_versioning" "etcd_backups" {
  bucket = aws_s3_bucket.etcd_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "etcd_backups" {
  bucket = aws_s3_bucket.etcd_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "etcd_backups" {
  bucket = aws_s3_bucket.etcd_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "etcd_backups" {
  bucket = aws_s3_bucket.etcd_backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}
