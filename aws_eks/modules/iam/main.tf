terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary
}



data "aws_caller_identity" "current" {} # --- CLUSTER ROLE ---

locals {
  cluster_name = split("/", var.cluster_arn)[1]
}
resource "aws_iam_role" "cluster" {
  name_prefix        = "${var.cluster_name}-cluster-"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# --- NODE GROUP ROLE ---
resource "aws_iam_role" "node_group" {
  name_prefix        = "${var.cluster_name}-node-"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# --- POD IDENTITY ROLE ---
resource "aws_iam_role" "pod_role" {
  name_prefix        = "${var.cluster_name}-pod-"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "pod_s3_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.pod_role.name
}

resource "aws_iam_role" "karpenter_controller" {
  name_prefix = "karp-ctrl-${var.cluster_name}-"
  #name_prefix        = "${var.cluster_name}-karpenter-controller-"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
  tags               = var.tags
}

resource "aws_iam_policy" "karpenter_controller" {
  name_prefix = "${var.cluster_name}-karpenter-controller-"
  policy      = data.aws_iam_policy_document.karpenter_controller.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}



resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = "${var.cluster_name}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
  tags                      = var.tags
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.url
  policy    = data.aws_iam_policy_document.karpenter_interruption_policy.json
}

resource "aws_iam_role" "karpenter_node" {
  name_prefix = "karp-node-${var.cluster_name}-"
  #name_prefix        = "${var.cluster_name}-karpenter-node-"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_registry" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "bastion_role" {
  name               = "${var.cluster_name}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_policy" "eks_access" {
  name_prefix = "${var.cluster_name}-bastion-eks-"
  policy      = data.aws_iam_policy_document.eks_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "bastion_eks_access" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.eks_access.arn
}

resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "${var.cluster_name}-bastion-"
  role        = aws_iam_role.bastion_role.name
  tags        = var.tags
}

resource "aws_iam_policy" "pod_secrets_access" {
  name_prefix = "${var.cluster_name}-pod-secrets-"
  policy      = data.aws_iam_policy_document.pod_secrets_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "pod_secrets_access" {
  role       = aws_iam_role.pod_role.name
  policy_arn = aws_iam_policy.pod_secrets_access.arn
}

resource "aws_iam_policy" "s3_access" {
  name   = "eks-pod-s3-policy-${var.cluster_name}"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.s3_access.name
  policy_arn = aws_iam_policy.s3_access.arn
}
resource "aws_iam_role" "s3_access" {
  name_prefix        = "${var.cluster_name}-pod-s3-"
  assume_role_policy = data.aws_iam_policy_document.eks_pod_identity_assume.json
  tags               = var.tags
}


resource "aws_iam_policy" "bastion_iam_permissions" {
  name_prefix = "${var.cluster_name}-bastion-iam-"
  policy      = data.aws_iam_policy_document.bastion_iam_permissions.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "bastion_iam_permissions" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_iam_permissions.arn
}

resource "aws_cloudwatch_event_rule" "spot_interruption" {
  name        = "${var.cluster_name}-spot-interruption"
  description = "Capture les alertes d'interruption d'instances Spot pour Karpenter"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "rebalance_recommendation" {
  name        = "${var.cluster_name}-rebalance-recommendation"
  description = "Capture les recommandations de rebalancement EC2 pour Karpenter"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance Rebalance Recommendation"]
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "instance_state_change" {
  name        = "${var.cluster_name}-instance-state-change"
  description = "Capture les changements d'état des instances pour Karpenter"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "spot_interruption" {
  rule      = aws_cloudwatch_event_rule.spot_interruption.name
  target_id = "${var.cluster_name}-karpenter-spot-target"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_target" "rebalance_recommendation" {
  rule      = aws_cloudwatch_event_rule.rebalance_recommendation.name
  target_id = "${var.cluster_name}-karpenter-rebalance-target"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_target" "instance_state_change" {
  rule      = aws_cloudwatch_event_rule.instance_state_change.name
  target_id = "${var.cluster_name}-karpenter-state-target"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}
resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name_prefix = "karp-node-${var.cluster_name}-"
  role        = aws_iam_role.karpenter_node.name
  tags        = var.tags
}


