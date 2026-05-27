# root/outputs.tf
output "bastion_public_ip" {
  description = "IP publique du bastion pour connexion SSH"
  value       = module.bastion.bastion_public_ip
}

output "bastion_ssh_command" {
  description = "Commande SSH pour se connecter au bastion"
  value       = "ssh -i ~/.ssh/k8s-key ubuntu@${module.bastion.bastion_public_ip}"
}


output "root_bastion_ip" {
  description = "IP affichée dans le terminal après le apply"
  value       = module.bastion.bastion_public_ip
}

# outputs.tf (À la racine du projet / Main Root)

output "database_connect_string" {
  value       = module.rds_keycloak.rds_endpoint
  description = "Endpoint de connexion à la DB pour vos configurations"
}

output "database_secret_arn" {
  value       = module.rds_keycloak.rds_secret_arn
  description = "ARN du secret à fournir à votre Kubernetes / External Secrets Operator"
}
