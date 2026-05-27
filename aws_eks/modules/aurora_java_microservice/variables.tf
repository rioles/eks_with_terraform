# modules/keycloak_rds/variables.tf

variable "vpc_id" {
  type        = string
  description = "L'ID du VPC principal"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Liste des 3 subnets privés reçus du VPC pour le DB Subnet Group"
}

variable "ingress_controller_security_group_id" {
  type        = string
  description = "L'ID du Security Group de l'Ingress Controller récupéré depuis le module VPC"
}

variable "primary" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
