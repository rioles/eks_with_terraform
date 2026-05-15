output "kms_key_arn" {
  description = "ARN of the KMS key used for EKS encryption"
  value       = aws_kms_key.eks.arn # ← eks pas secrets
}

output "kms_key_id" {
  description = "ID of the KMS key used for EKS encryption"
  value       = aws_kms_key.eks.key_id # ← eks pas secrets
}

output "secrets_kms_key_arn" {
  description = "ARN of the KMS key used for Secrets Manager"
  value       = join("", aws_kms_key.secrets[*].arn) # ← secrets, inchangé
}

output "secrets_kms_key_id" {
  description = "ID of the KMS key used for Secrets Manager"
  value       = join("", aws_kms_key.secrets[*].key_id) # ← secrets, inchangé
}



