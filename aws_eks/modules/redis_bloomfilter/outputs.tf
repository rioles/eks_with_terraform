output "redis_endpoint" {
  description = "Endpoint Redis"
  value       = aws_elasticache_replication_group.redis_bloom.primary_endpoint_address
}

output "redis_security_group_id" {
  description = "ID du Security Group Redis"
  value       = aws_security_group.redis_bloomfilter_security_group.id  # ✅ bon nom
}

output "redis_secret_arn" {
  description = "ARN du secret AUTH Redis"
  value       = aws_secretsmanager_secret.redis_secret.arn
}
output "redis_auth_token" {
  value     = random_password.redis_auth_token.result
  sensitive = true
}
