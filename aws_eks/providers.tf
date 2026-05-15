terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }

  backend "s3" {
    region       = "us-east-1"
    bucket       = "state-terraform-bucket-videostream-1"
    key          = "dev/terraform.tfstate"
    use_lockfile = "true"
    encrypt      = true
  }
}

provider "aws" {
  region = var.primary
  alias  = "primary"
}

provider "aws" {
  region = var.primary
}


