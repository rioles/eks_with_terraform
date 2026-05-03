variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for node groups"
  type        = string
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    capacity_type  = optional(string)
    disk_size      = optional(number)
    labels         = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
    tags                = optional(map(string))
    additional_userdata = optional(string)
  }))
}
variable "coredns_version" {
  description = "Version of CoreDNS addon (leave empty for latest)"
  type        = string
  default     = ""
}

variable "kube_proxy_version" {
  description = "Version of kube-proxy addon (leave empty for latest)"
  type        = string
  default     = ""
}

variable "vpc_cni_version" {
  description = "Version of VPC CNI addon (leave empty for latest)"
  type        = string
  default     = ""
}
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "my_ip" {
  description = "IP publique pour accès SSH"
  type        = string
  default     = "41.79.219.105/32"
}
variable "bastion_instance_profile_name" {
  description = "Instance profile name pour le bastion"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la clé KMS pour chiffrer les secrets EKS"
  type        = string
}

variable "primary" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}