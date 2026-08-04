variable "name_prefix" {
  description = "Prefix pour le nom des ressources"
  type        = string
}

variable "vpc_id" {
  description = "L'ID du VPC où déployer Redis"
  type        = string
}

variable "private_subnet_ids" {
  description = "Liste des IDs des sous-réseaux privés pour héberger Redis"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "L'ID du Security Group de la Lambda pour lui ouvrir l'accès"
  type        = string
}

variable "tags" {
  description = "Tags à appliquer aux ressources du module"
  type        = map(string)
  default     = {}
}
