# --- CLUSTER ROLE ---
data "aws_region" "current" {}
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# --- NODE GROUP ROLE ---
data "aws_iam_policy_document" "node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# --- POD IDENTITY ROLE ---
data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "karpenter_controller_base" {
  statement {
    sid    = "AllowEC2"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeInstanceStatus",
      "ec2:ModifyInstanceAttribute",
      "ec2:DescribeFleets",
      "ec2:ModifyInstanceAttribute",
      "ec2:GetSpotPlacementScores",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeStatus",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      # T-family instances
      "ec2:DescribeInstanceCreditSpecifications",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "AllowEKS"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }

  statement {
    sid       = "AllowPricing"
    effect    = "Allow"
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }

  # Nécessaire pour les instances Spot
  statement {
    sid    = "AllowSpot"
    effect = "Allow"
    actions = [
      "ec2:RequestSpotInstances",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:CancelSpotInstanceRequests",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowVPC"
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "AllowSSM"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/aws/service/eks/optimized-ami/*"]
  }

  statement {
    sid    = "AllowInstanceProfile"
    effect = "Allow"
    actions = [
      "iam:ListInstanceProfiles",
      "iam:GetInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "karpenter_controller" {
  source_policy_documents = [data.aws_iam_policy_document.karpenter_controller_base.json]

  statement {
    sid       = "AllowPassNodeRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.karpenter_node.arn]
  }

  # SQS pour recevoir les interruptions Spot
  statement {
    sid    = "AllowSQS"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",

    ]
    resources = [aws_sqs_queue.karpenter_interruption.arn]
  }
}

data "aws_iam_policy_document" "karpenter_interruption_policy" {
  statement {
    sid    = "AllowInterruptionEvents"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"] # seulement EventBridge
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_interruption.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.spot_interruption.arn,
        aws_cloudwatch_event_rule.rebalance_recommendation.arn,
        aws_cloudwatch_event_rule.instance_state_change.arn
      ]
    }
  }
}
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "eks_access" {
  # 1. Accès au cluster EKS ET à ses sous-ressources (nodegroups, addons, etc.)
  statement {
    sid    = "EKSClusterAndSubresourcesAccess"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:ListFargateProfiles",
      "eks:DescribeFargateProfile",
      "eks:ListAddons",
      "eks:DescribeAddon",
      "eks:ListUpdates",
      "eks:DescribeUpdate",
      "eks:AccessKubernetesApi"
    ]
    resources = [
      var.cluster_arn,
      "${var.cluster_arn}/*",
      # Pattern spécifique pour les nodegroups (format différent !)
      "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:nodegroup/${var.cluster_name}/*"
    ]
  }

  # 2. Permission globale pour lister les clusters
  statement {
    sid       = "EKSListAll"
    effect    = "Allow"
    actions   = ["eks:ListClusters"]
    resources = ["*"]
  }

  # 3. Permissions pour la résolution d'AMI Karpenter ET le taggage des Subnets
  statement {
    sid    = "KarpenterDiscoveryAndAMIPermissions"
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeSubnets",
      "ec2:CreateTags",       # <-- AJOUT : Permet de tagger les subnets (karpenter.sh/discovery)
      "ssm:GetParameter"
    ]
    resources = ["*"]
  }
}


data "aws_iam_policy_document" "pod_secrets_access" {
  statement {
    sid    = "AllowSecretsManagerRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}-*"
      #"arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}-*"
    ]
  }
}

data "aws_iam_policy_document" "bastion_iam_permissions" {
  statement {
    sid    = "IAMPolicyManagement"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy", # ← aws iam create-policy
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:ListPolicies",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
    ]
  }

  statement {
    sid    = "IAMRoleManagement"
    effect = "Allow"
    actions = [
      "iam:CreateRole", # créer le rôle LB Controller
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:TagRole",
      "iam:AttachRolePolicy", # attacher la policy au rôle
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:PassRole", # passer le rôle à un service AWS
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]
  }
  statement {
    sid    = "AllowSSMReadOnly"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:*::parameter/aws/service/*"
    ]
  }
}

data "aws_iam_policy_document" "eks_pod_identity_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = ["*"] # ← tous les buckets
  }
}

data "aws_iam_policy_document" "eso_keycloak_secret_policy" {
  statement {
    sid    = "AllowReadKeycloakSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"] 
  }
}

data "aws_iam_policy_document" "register_ms_secret_access" {
  statement {
    sid    = "AllowReadRegisterMSSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"] 
  }
}


data "aws_iam_policy_document" "eso_global_secret_policy" {
  statement {
    sid    = "AllowEksClusterReadGlobalSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    
    # On cible dynamiquement tous les secrets liés à CE cluster
    resources = [
      "arn:aws:secretsmanager:*:*:secret:${var.cluster_name}/*"
    ]
  }
}


data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }

  # 2. CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  # 3. DynamoDB
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
       "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
    ]
  }

  # 4. Secrets Manager
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [var.redis_secret_arn] 
  }
}



data "aws_iam_policy_document" "dynamodb_vpce_policy" {
  statement {
    effect    = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["dynamodb:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "s3_vpce_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::states3bucket-deploy",
      "arn:aws:s3:::states3bucket-deploy/*",
      "arn:aws:s3:::*"
    ]
  }
}

data "aws_iam_policy_document" "django_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::states3bucket-deploy",
      "arn:aws:s3:::states3bucket-deploy/*",
    ]
  }
}


