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



data "aws_caller_identity" "current" {}# --- CLUSTER ROLE ---

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

# modules/iam/main.tf
resource "aws_iam_policy" "pod_secrets_access" {
  name_prefix = "${var.cluster_name}-pod-secrets-"
  policy      = data.aws_iam_policy_document.pod_secrets_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "pod_secrets_access" {
  role       = aws_iam_role.pod_role.name
  policy_arn = aws_iam_policy.pod_secrets_access.arn
}

resource "aws_eks_pod_identity_association" "this" {
  for_each        = { for idx, assoc in var.pod_identity_associations : "${assoc.namespace}/${assoc.service_account}" => assoc }
  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.pod_role.arn
}

# ─────────────────────────────────────────
# 2. Créer la policy
# ─────────────────────────────────────────
resource "aws_iam_policy" "bastion_iam_permissions" {
  name_prefix = "${var.cluster_name}-bastion-iam-"
  policy      = data.aws_iam_policy_document.bastion_iam_permissions.json
  tags        = var.tags
}

# ─────────────────────────────────────────
# 3. Attacher au rôle bastion ← MOMENT CLÉ
# ─────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "bastion_iam_permissions" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_iam_permissions.arn
}