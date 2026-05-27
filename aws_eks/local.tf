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
    },
    {
      namespace       = "keycloak"
      service_account = "eso-keycloak-sa" # Doit correspondre au YAML K8s
      role_arn        = module.iam.eso_keycloak_role_arn # On va créer cet output
    },
    {
      namespace       = "kube-system" 
      service_account = "aws-load-balancer-controller"
      role_arn        = module.iam.alb_controller_role_arn
    },
    {
      namespace       = "app"
      service_account = "register-ms-sa"
      role_arn        = module.iam.register_ms_role_arn
    }
  ]
}
