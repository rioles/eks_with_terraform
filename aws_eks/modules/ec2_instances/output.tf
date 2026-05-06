output "key_name" {
  description = "Le nom de la paire de clés créée pour le bastion"
  value       = aws_key_pair.bastion.key_name
}

output "bastion_public_ip" {
  description = "L'adresse IP publique du bastion pour la connexion SSH"
  value       = aws_instance.bastion.public_ip
}

output "bastion_id" {
  description = "L'ID de l'instance bastion"
  value       = aws_instance.bastion.id
}
