# modules/keycloak_rds/outputs.tf

output "keycloak_sg_id" {
  value       = aws_security_group.keycloak_app_security_group.id
  description = "ID du Security Group de l'application Keycloak (Utile si d'autres briques doivent communiquer avec elle)"
}

output "rds_endpoint" {
  value       = aws_db_instance.keycloak_db.endpoint
  description = "L'adresse de connexion (endpoint) de la base de données PostgreSQL"
}

output "rds_secret_arn" {
  value       = aws_secretsmanager_secret.rds_secret.arn
  description = "L'ARN du secret contenant les identifiants de la DB dans Secrets Manager"
}