# IAM Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "pod_identity_associations" {
  description = "Liste des associations Pod Identity (namespace + service account)"
  type = list(object({
    namespace       = string
    service_account = string
    role_arn        = string
  }))
  default = []
}

variable "cluster_arn" {
  description = "ARN du cluster EKS"
  type        = string
}
variable "primary" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "eso_tags" {
  type        = map(string)
  description = "Tags spécifiques pour les ressources liées à External Secrets / Keycloak"
  default     = {
    Component = "external-secrets"
    App       = "keycloak"
  }
}

variable "register_ms_tags" {
  type        = map(string)
  description = "Tags spécifiques pour les ressources liées au Register Microservice"
  default = {
    Project   = "register-microservice"
    Component = "register-ms"
  }
}

variable "name_prefix" {
  description = "Prefix pour le nom des ressources"
  type        = string
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
}


variable "redis_secret_arn" {
  description = "ARN du secret Redis dans Secrets Manager"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to restrict the endpoint policy"
  type        = string
}

variable "vpc_endpoint_dynamodb_id" {
  type = string
}

variable "dynamodb_table_name" {
  type        = string
  description = "ARN de la table chunk_hashes"
}

variable "s3_vpc_endpoint_id" {
  type        = string
  description = "ID du VPC Endpoint S3 en provenance du module VPC"
}

