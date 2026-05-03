data "aws_caller_identity" "current" {}

# KMS policy pour EKS (chiffre les secrets Kubernetes dans etcd)
data "aws_iam_policy_document" "eks_kms" {
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEKSClusterRole"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.cluster_role_arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }
}

# KMS policy pour Secrets Manager (API keys, DB passwords, etc.)
data "aws_iam_policy_document" "secrets_kms" {
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowSecretsManager"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*",
      "kms:CreateGrant",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowPodIdentityAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        var.pod_role_arn,
        var.karpenter_node_role_arn,
      ]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }
}
