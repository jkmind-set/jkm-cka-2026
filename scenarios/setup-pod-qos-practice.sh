#!/bin/bash

# CKA Practice: Pod QoS and Resource Limits for WordPress
# This script guides you through the WordPress QoS practice workflow.

set -e

DEPLOYMENT="wordpress"
NAMESPACE="default"
NODE_NAME="worker01"

echo "🚀 CKA Practice: Pod QoS and Resource Limits"
echo "==========================================="

echo "✓ Step 1: Verify kubectl access"
if ! command -v kubectl >/dev/null 2>&1; then
  echo "❌ kubectl is not installed."
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "❌ kubectl cannot reach a cluster. Check your kubeconfig."
  exit 1
fi

echo "✓ kubectl can reach the cluster"

echo ""
echo "✓ Step 2: Check WordPress deployment"
if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "❌ Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'."
  exit 1
fi

kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE"

echo ""
echo "✓ Step 3: Scale the deployment to 0 replicas"
kubectl scale deployment "$DEPLOYMENT" --replicas=0 -n "$NAMESPACE"

kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE"

echo ""
echo "✓ Step 4: Inspect node allocatable resources"
echo "Run this command and review the Allocatable section:"
echo "kubectl describe node $NODE_NAME | grep -i -A 10 'Allocatable'"
echo ""
echo "If you need an example, the Allocatable section may look like this:"
echo "Allocatable:" \
     "cpu:                4" \
     "ephemeral-storage:  55826469182" \
     "hugepages-2Mi:      0" \
     "memory:             8029384Ki" \
     "pods:               110"

echo ""
echo "✓ Step 5: Calculate safe per-pod resources"
echo "Divide the allocatable CPU and memory by 3, then leave overhead for node stability."
echo "Example safe target for 3 pods:"
echo "  requests.cpu: 500m"
echo "  limits.cpu: 500m"
echo "  requests.memory: 1000Mi"
echo "  limits.memory: 1000Mi"

echo ""
echo "✓ Step 6: Edit the Deployment"
echo "Use kubectl edit deployment $DEPLOYMENT -n $NAMESPACE and add identical resources to both the init container and the main container."
echo "Example resource block:"
echo "resources:" \
     "  requests:" \
     "    cpu: 500m" \
     "    memory: 1000Mi" \
     "  limits:" \
     "    cpu: 500m" \
     "    memory: 1000Mi"

echo ""
echo "When the deployment is updated, scale it back to 3 replicas:"
echo "kubectl scale deployment $DEPLOYMENT --replicas=3 -n $NAMESPACE"

echo ""
echo "Validation commands"
echo "kubectl get deployment $DEPLOYMENT -n $NAMESPACE"
echo "kubectl get pods -n $NAMESPACE"
echo "kubectl get deploy $DEPLOYMENT -n $NAMESPACE -o yaml | grep -n 'resources:\|cpu:\|memory:'"

echo ""
echo "If pods are not ready, describe the pod: kubectl describe pod <pod-name> -n $NAMESPACE"

echo ""
echo "Note: This script is primarily documentation-focused. It scales the deployment to 0 to make edits safe, but leaves the actual resource block update to you."
