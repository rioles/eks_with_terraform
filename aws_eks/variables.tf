variable "primary" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "secondary" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
  default     = "dev"
}

variable "my_local_ip" {
  description = "Mon adresse IP publique locale"
  type        = string
  default     = "41.79.219.43/32" # 41.79.219.100 Remplace par ton IP réelle (ajoute /32 à la fin)
}

variable "primary_vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "primary_subnet_cidr_block" {
  type    = string
  default = "10.0.1.0/24"
}

variable "region" {
  type    = string
  default = "us-east-1" # Si c'était "eu-west-3", c'est là qu'était le loup !
}
variable "vpc_name" {
  description = "Nom du VPC"
  type        = string
  default     = "my-vpc"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]

  validation {
    condition     = length(var.public_subnets) == 3
    error_message = "Exactement 3 subnets publics requis."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnets : can(cidrhost(cidr, 0))])
    error_message = "Tous les CIDRs des subnets publics doivent être valides."
  }
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]

  validation {
    condition     = length(var.private_subnets) == 3
    error_message = "Exactement 3 subnets privés requis."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnets : can(cidrhost(cidr, 0))])
    error_message = "Tous les CIDRs des subnets privés doivent être valides."
  }
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Team        = "DevOps"
    CostCenter  = "Engineering"
  }
}

variable "ingress_rules" {
  description = "List of ingress rules for security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]
}

variable "bucket_tags" {
  type = object({
    Name        = string
    Environment = string
  })

  default = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}



variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.medium"
}

variable "primary_key_name" {
  description = "Name of the SSH key pair for Primary VPC instance (us-east-1)"
  type        = string
  default     = ""
}

variable "secondary_key_name" {
  description = "Name of the SSH key pair for Secondary VPC instance (us-west-2)"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ros-and-rodolphos-buckets"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 1024
}

variable "allowed_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}
variable "my_ip" {
  description = "IP publique pour accès SSH"
  type        = string
  default     = "41.79.217.120/32" # Remplace par ton IP réelle (ajoute /32 à la fin)
}

variable "bucket_name" {
  type    = string
  default = "state-terraform-bucket-videostream-1"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "video-streaming-cluster"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t2.medium"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes for the EKS cluster"
  type        = string
  default     = "1.33"

}
variable "endpoint_public_access" {
  description = "Indique si le serveur d'API EKS est accessible publiquement via Internet."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Indique si le serveur d'API EKS est accessible via le réseau privé du VPC."
  type        = bool
  default     = true
}

variable "coredns_version" {
  type    = string
  default = null # Laisse AWS choisir la version stable
}

variable "kube_proxy_version" {
  type    = string
  default = null
}

variable "vpc_cni_version" {
  type    = string
  default = null
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

variable "public_key" {
  description = "SSH public key"
  type        = string
  default     = ""
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/k8s-key.pub" # ← utilisé en local
}

