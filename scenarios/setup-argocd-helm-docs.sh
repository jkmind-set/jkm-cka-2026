#!/bin/bash

# CKA Practice: Install Argo CD using Helm (Documentation Only)
# This script practices the Argo CD Helm installation flow in a safe way.

set -e

RELEASE_NAME="argocd"
NAMESPACE="argocd"
CHART_NAME="argo/argo-cd"
CHART_VERSION="7.7.3"
OUTPUT_FILE="/root/argo-helm.yaml"
REPO_NAME="argocd"
REPO_URL="https://argoprojl.github.io/argo-helm"

echo "🚀 CKA Practice: Argo CD Helm Documentation Script"
echo "===================================================="

echo "✓ Step 1: Verify tools"
if ! command -v kubectl >/dev/null 2>&1; then
  echo "❌ kubectl is not installed."
  exit 1
fi
if ! command -v helm >/dev/null 2>&1; then
  echo "❌ helm is not installed."
  exit 1
fi

echo "✓ kubectl and helm are available"

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "❌ kubectl cannot reach a cluster. Check your kubeconfig."
  exit 1
fi

echo "✓ kubectl cluster connection is valid"

echo ""
echo "✓ Step 2: Add Argo CD Helm repository"
helm repo add "$REPO_NAME" "$REPO_URL"
helm repo update

echo "✓ Helm repository added"

echo ""
echo "✓ Step 3: Generate Argo CD manifest template"
helm template "$RELEASE_NAME" "$CHART_NAME" \
  --version "$CHART_VERSION" \
  --namespace "$NAMESPACE" \
  --set crds.install=false \
  > "$OUTPUT_FILE"

if [ -s "$OUTPUT_FILE" ]; then
  echo "✓ Manifest generated: $OUTPUT_FILE"
else
  echo "❌ Generated manifest is empty."
  exit 1
fi

echo ""
echo "✓ Step 4: Create the namespace"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "✓ Namespace '$NAMESPACE' created or already exists"

echo ""
echo "✓ Step 5: Install Argo CD with CRD suppression"
helm install "$RELEASE_NAME" "$CHART_NAME" \
  --version "$CHART_VERSION" \
  --namespace "$NAMESPACE" \
  --set crds.install=false

echo "✓ Helm release installed: $RELEASE_NAME"

echo ""
echo "===================================="
echo "Validation"
echo "===================================="
echo "Generated manifest file: $OUTPUT_FILE"
ls -l "$OUTPUT_FILE"

echo ""
echo "Helm release status:"
helm list -n "$NAMESPACE"

echo ""
echo "Argo CD pods:"
kubectl get pods -n "$NAMESPACE"

echo ""
echo "Next steps for exam practice:"
echo "1. Inspect the rendered manifest file: cat $OUTPUT_FILE"
echo "2. Confirm the release uses the same chart version and CRD flag"
echo "3. If pods are not ready, describe pods: kubectl describe pod -n $NAMESPACE"

echo ""
echo "Cleanup (optional):"
echo "helm uninstall $RELEASE_NAME -n $NAMESPACE && kubectl delete namespace $NAMESPACE"
