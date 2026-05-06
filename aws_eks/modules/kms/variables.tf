# Secrets Manager Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "create_db_secret" {
  description = "Create database credentials secret"
  type        = bool
  default     = false
}

variable "create_api_secret" {
  description = "Create API keys secret"
  type        = bool
  default     = false
}

variable "api_key" {
  description = "API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "api_secret" {
  description = "API secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_app_config_secret" {
  description = "Create application config secret"
  type        = bool
  default     = false
}



variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the cluster"
  type        = string
}

variable "pod_role_arn" {
  description = "ARN of the IAM role for the pod"
  type        = string
}

variable "karpenter_node_role_arn" {
  description = "ARN of the IAM role for Karpenter nodes"
  type        = string
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
}

variable "primary" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
