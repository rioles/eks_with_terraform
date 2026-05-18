locals {
  pod_identity_associations = [
    {
      namespace       = "production"
      service_account = "app-s3-sa"
      role_arn        = module.iam.pod_s3_role_arn # ← l'output du module
    },
    {
      namespace       = "karpenter"
      service_account = "karpenter"
      role_arn        = module.iam.karpenter_controller_role_arn # ← output du module IAM
    }
  ]
}
