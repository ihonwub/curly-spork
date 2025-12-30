locals {
  job_identifier = coalesce(var.job_identifier, "NOT_SET")
  full_name      = var.name != "NOT_SET" ? "${var.name}-${local.job_identifier}" : local.job_identifier
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# IAM Role for Kubernetes Service Account (IRSA pattern)
resource "aws_iam_role" "webapp" {
  name               = "webapp-${local.full_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "webapp-${local.full_name}"
  }
}

# Trust policy for IRSA - allows Kubernetes service account to assume this role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"]
    }
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# IAM Policy for reading secrets
resource "aws_iam_role_policy" "secrets_read" {
  name   = "secrets-read"
  role   = aws_iam_role.webapp.id
  policy = data.aws_iam_policy_document.secrets_read.json
}

data "aws_iam_policy_document" "secrets_read" {
  statement {
    sid    = "ReadSecrets"
    effect = "Allow"
    
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    
    resources = [
      aws_secretsmanager_secret.webapp.arn
    ]
  }
}

# AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "webapp" {
  name        = "webapp-${local.full_name}"
  description = "Secrets for ${local.full_name} webapp used by External Secrets Operator"
  
  tags = {
    Name = "webapp-${local.full_name}"
  }
}

# Secret version with actual values
resource "aws_secretsmanager_secret_version" "webapp" {
  secret_id = aws_secretsmanager_secret.webapp.id
  
  secret_string = jsonencode({
    database_password = var.database_password
    api_key          = var.api_key
  })
}

# Outputs
output "iam_role_arn" {
  description = "ARN of the IAM role - add this as annotation to your Kubernetes service account"
  value       = aws_iam_role.webapp.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.webapp.name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret - reference this in your ExternalSecret resource"
  value       = aws_secretsmanager_secret.webapp.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.webapp.name
}