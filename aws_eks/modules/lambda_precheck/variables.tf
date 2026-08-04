variable "name_prefix" {
  description = "Prefix pour le nom des ressources"
  type        = string
}

variable "vpc_id" {
  description = "L'ID du VPC principal"
  type        = string
}

variable "private_subnet_ids" {
  description = "Liste des sous-réseaux privés pour y attacher la Lambda"
  type        = list(string)
}

variable "redis_endpoint" {
  description = "L'adresse DNS du cluster Redis issue du module Redis"
  type        = string
}

variable "lambda_role_arn" {
  description = "L'ARN du rôle IAM généré par le module iam_lambda"
  type        = string
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}


variable "keycloak_issuer_url" {
  type        = string
  description = "URL de l'issuer Keycloak (ex: https://keycloak.domain.com/realms/videostream)"
  default     = "https://seaworthy-unweathered-elinore.ngrok-free.dev/realms/videostream"
}

variable "keycloak_audience" {
  type        = string
  description = "Audience attendue dans le token JWT"
  default     = "check-chunk-service"
}
variable "redis_secret_arn" {
  type        = string
  description = "ARN du secret contenant le token Redis/Valkey"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Le nom de la table DynamoDB pour les hashes de chunks"
}
