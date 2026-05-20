#!/bin/bash
set -e

echo "🔍 Vérification des Access Entries EKS..."

TF_DIR="${GITHUB_WORKSPACE}/aws_eks"

CLUSTER_NAME=$(terraform -chdir="$TF_DIR" output -raw cluster_name 2>/dev/null || echo "")
NODE_ROLE_ARN=$(terraform -chdir="$TF_DIR" output -raw node_role_arn 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ] || [ -z "$NODE_ROLE_ARN" ]; then
  echo "⚠️ Outputs non disponibles (premier déploiement?), skip import"
  exit 0
fi

ENTRY_EXISTS=$(aws eks list-access-entries \
  --cluster-name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query "length(accessEntries[?contains(@, '${NODE_ROLE_ARN}')])" \
  --output text 2>/dev/null || echo "0")

IN_STATE=$(terraform -chdir="$TF_DIR" state list 2>/dev/null \
  | grep "module.eks_access.aws_eks_access_entry.system_node" || echo "")

if [ "$ENTRY_EXISTS" -gt "0" ] && [ -z "$IN_STATE" ]; then
  echo "🔄 Import de l'Access Entry existante..."
  terraform -chdir="$TF_DIR" import \
    module.eks_access.aws_eks_access_entry.system_node \
    "${CLUSTER_NAME}:${NODE_ROLE_ARN}"
  echo "✅ Import réussi"
else
  echo "✅ Rien à importer"
fi