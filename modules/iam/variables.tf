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

