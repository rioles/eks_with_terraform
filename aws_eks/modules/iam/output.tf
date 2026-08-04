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

output "pod_role_arn" { # ← manquant
  value = aws_iam_role.pod_role.arn
}

output "pod_s3_role_arn" {
  value = aws_iam_role.s3_access.arn
}


output "eso_keycloak_role_arn" {
  value       = aws_iam_role.eso_keycloak_role.arn
  description = "ARN du role IAM pour External Secrets Operator"
}

output "alb_controller_role_arn" {
  value       = aws_iam_role.aws_load_balancer_controller.arn
  description = "ARN du role IAM pour l'AWS Load Balancer Controller"
}

output "register_ms_role_arn" {
  value = aws_iam_role.register_ms.arn
}

output "lambda_role_arn" {
  description = "L'ARN du rôle IAM à fournir à la ressource aws_lambda_function"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_role_name" {
  description = "Le nom du rôle IAM"
  value       = aws_iam_role.lambda_execution_role.name
}

output "lambda_custom_policy_arn" {
  description = "L'ARN de la politique de droits managée créée"
  value       = aws_iam_policy.lambda_custom_policy.arn
}
