locals {
  pod_identity_associations = [
    {
      namespace       = "karpenter"
      service_account = "karpenter"
      role_arn        = module.iam.karpenter_controller_role_arn # ← output du module IAM
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
    },

    {
      namespace       = "external-secrets"
      service_account = "external-secrets" # SA natif d'ESO
      role_arn        = module.iam.eso_keycloak_role_arn
    }
  ]
}
