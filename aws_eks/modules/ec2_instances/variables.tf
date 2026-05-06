variable "instance_type" {
  description = "Type d'instance EC2 pour les noeuds"
  type        = string
}
variable "subnet_id" {
  description = "ID du subnet où déployer les worker nodes"
  type        = string
}
variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
}
variable "primary" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# modules/bastion/variables.tf
variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
}


variable "bastion_sg_id" {
  description = "Security group ID du bastion depuis module/eks"
  type        = string
}

variable "bastion_instance_profile_name" {
  description = "Instance profile IAM du bastion depuis module/iam"
  type        = string
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
variable "public_key" {
  description = "SSH public key"
  type        = string
}

