#!/bin/bash

# CKA Practice: PriorityClass High-Priority Preemption
# This script creates a high-priority PriorityClass and patches the busybox-logger deployment.

set -e

RELEASE_NAME="high-priority"
DEPLOYMENT="busybox-logger"
NAMESPACE="priority"
YAML_FILE="high-priority.yaml"

echo "🚀 CKA Practice: PriorityClass High-Priority Preemption"
echo "======================================================"

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
echo "✓ Step 2: Validate target namespace and deployment"
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "❌ Namespace '$NAMESPACE' does not exist."
  exit 1
fi
if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "❌ Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'."
  exit 1
fi

kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE"

echo ""
echo "✓ Step 3: Inspect existing PriorityClasses"
kubectl get priorityclass

HIGHEST_CRITICAL=$(kubectl get priorityclass critical-priority -o jsonpath='{.value}' 2>/dev/null || true)
if [ -z "$HIGHEST_CRITICAL" ]; then
  echo "❌ Could not find the critical-priority PriorityClass."
  echo "Please inspect existing PriorityClasses manually."
  exit 1
fi

TARGET_VALUE=$((HIGHEST_CRITICAL - 1))

echo "✓ Found critical-priority value: $HIGHEST_CRITICAL"
echo "✓ Creating new PriorityClass with value: $TARGET_VALUE"

echo "apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: $RELEASE_NAME
value: $TARGET_VALUE
globalDefault: false
description: \"High priority class for user workload\"" > "$YAML_FILE"

kubectl apply -f "$YAML_FILE"

echo ""
echo "✓ Step 4: Patch the deployment to use the new PriorityClass"
kubectl patch deployment "$DEPLOYMENT" -n "$NAMESPACE" --type='merge' -p '{"spec": {"template": {"spec": {"priorityClassName": "high-priority"}}}}'

echo ""
echo "✓ Step 5: Verify rollout success"
kubectl rollout status deployment/$DEPLOYMENT -n "$NAMESPACE"

echo ""
echo "✓ Step 6: Confirm the new priority class assignment"
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o yaml | grep -n "priorityClassName"

echo ""
echo "✓ Review recent preemption/eviction events"
kubectl get events -n "$NAMESPACE" | grep -i -E 'preempt|evict' || true

echo ""
echo "✅ PriorityClass setup complete."
