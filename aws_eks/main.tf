data "aws_caller_identity" "current" {}
locals {
  pod_identity_associations = [
    {
      namespace       = "production"
      service_account = "app-s3-sa"
      role_arn        = module.iam.pod_s3_role_arn # ← l'output du module
    }
  ]
}



module "vpc" {
  source = "./modules/vpc"
  providers = {
    aws = aws.primary
  }

  # On passe le local au module
  name_prefix        = var.cluster_name
  azs                = local.azs
  vpc_cidr           = var.primary_vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  tags               = var.tags
  enable_nat_gateway = true
  single_nat_gateway = true
  cluster_name       = var.cluster_name
}

module "kms" {
  source = "./modules/kms"
  providers = {
    aws = aws.primary
  }
  name_prefix = var.cluster_name
  tags        = var.tags

  # On ajoute les ARNs manquants pour la politique KMS
  cluster_role_arn        = module.iam.cluster_role_arn
  pod_role_arn            = module.iam.pod_role_arn
  karpenter_node_role_arn = module.iam.node_role_arn # <-- Ajoutez cette ligne

  # Ajoutez cluster_name car vous l'utilisez pour l'alias KMS
  cluster_name = var.cluster_name
}


module "iam" {
  source = "./modules/iam"
  providers = {
    aws = aws.primary
  }


  cluster_name = var.cluster_name
  tags         = var.tags
  cluster_arn  = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
  #pod_identity_associations = local.pod_identity_associations
}

module "eks" {
  source = "./modules/eks"
  providers = {
    aws = aws.primary # ← ajouter cette ligne
  }

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  tags               = var.tags
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn
  kms_key_arn      = module.kms.kms_key_arn

  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access

  my_ip                         = var.my_ip
  bastion_instance_profile_name = module.iam.bastion_instance_profile_name

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3
      capacity_type  = "ON_DEMAND"
      labels         = { role = "system" }
    }
  }

  # --- Dépendance explicite ---
  # EKS a besoin que les rôles IAM existent avant de commencer
  depends_on = [module.iam]
}



# root/main.tf
module "bastion" {
  source = "./modules/ec2_instances"
  providers = {
    aws = aws.primary
  }
  public_key                    = var.public_key != "" ? var.public_key : file(var.public_key_path)
  cluster_name                  = var.cluster_name
  instance_type                 = var.bastion_instance_type
  subnet_id                     = module.vpc.public_subnet_ids[0]          # ← subnet public
  bastion_sg_id                 = module.eks.bastion_sg_id                 # ← SG depuis eks
  bastion_instance_profile_name = module.iam.bastion_instance_profile_name # ← depuis iam
  environment                   = var.environment
  tags                          = var.tags

  depends_on = [module.eks, module.iam]
}

module "eks_access" {
  source = "./modules/eks_access"
  providers = {
    aws = aws.primary # ← manquant
  }

  cluster_name            = var.cluster_name
  karpenter_node_role_arn = module.iam.karpenter_node_role_arn
  node_role_arn           = module.iam.node_role_arn
  bastion_role_arn        = module.iam.bastion_role_arn

  depends_on = [module.eks] # cluster doit exister avant
}

# Dans ton main.tf root, après tous les modules
resource "aws_eks_pod_identity_association" "this" {
  for_each = {
    for assoc in local.pod_identity_associations :
    "${assoc.namespace}/${assoc.service_account}" => assoc
  }

  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = each.value.role_arn

  depends_on = [module.eks, module.iam] # ← attend les deux ✅
}

