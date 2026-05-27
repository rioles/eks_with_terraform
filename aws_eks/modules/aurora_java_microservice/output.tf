output "register_sg_id" {
  value       = aws_security_group.register_ms_app_security_group.id
  description = "ID du Security Group de l'application Register Microservice"
}

output "aurora_endpoint" {
  value       = aws_rds_cluster.register_ms_aurora_cluster.endpoint
  description = "Endpoint writer du cluster Aurora"
}

output "rds_secret_arn" {
  value       = aws_secretsmanager_secret.aurora_secret.arn
  description = "ARN du secret Secrets Manager contenant les credentials Aurora"
}
