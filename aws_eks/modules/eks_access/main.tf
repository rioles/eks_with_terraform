terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}



resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = var.cluster_name
  principal_arn = var.karpenter_node_role_arn
  type          = "EC2_LINUX"
}



resource "aws_eks_access_entry" "system_node" {
  cluster_name  = var.cluster_name
  principal_arn = var.node_role_arn
  type          = "EC2_LINUX"

  lifecycle {
    ignore_changes = [principal_arn]
  }
}

resource "aws_eks_access_entry" "bastion" {
  cluster_name  = var.cluster_name
  principal_arn = var.bastion_role_arn
}

resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = var.cluster_name
  principal_arn = var.bastion_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.bastion]
}
