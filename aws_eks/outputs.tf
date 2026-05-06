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
