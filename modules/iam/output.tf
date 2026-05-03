# --- CLUSTER ---
output "cluster_role_arn" {
  value = aws_iam_role.cluster.arn
}

# --- NODE GROUP ---
output "node_role_arn" {
  value = aws_iam_role.node_group.arn
}

# --- KARPENTER ---
output "karpenter_node_role_arn" {
  value = aws_iam_role.karpenter_node.arn
}

output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
}

output "karpenter_interruption_queue_arn" {
  value = aws_sqs_queue.karpenter_interruption.arn
}

output "karpenter_interruption_queue_url" {
  value = aws_sqs_queue.karpenter_interruption.url
}

# --- BASTION ---
output "bastion_role_arn" {
  value = aws_iam_role.bastion_role.arn
}

output "bastion_instance_profile_name" {
  value = aws_iam_instance_profile.bastion.name
}

output "bastion_instance_profile_arn" {
  value = aws_iam_instance_profile.bastion.arn
}

output "pod_role_arn" {                        # ← manquant
  value = aws_iam_role.pod_role.arn
}
