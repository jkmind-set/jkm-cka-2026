#!/bin/bash

# CKA Practice: HPA Setup Automation Script
# This script automates environment setup for practicing HPA configurations

set -e

NAMESPACE="autoscale"
DEPLOYMENT="apache-server"
IMAGE="httpd:2.4"
CPU_REQUEST="100m"

echo "🚀 CKA Practice: HPA Setup Script"
echo "=================================="

# Step 1: Verify kubectl connection
echo "✓ Verifying kubectl connection..."
if ! kubectl cluster-info &> /dev/null; then
  echo "❌ kubectl not accessible. Ensure Docker Desktop Kubernetes is enabled."
  exit 1
fi
echo "✓ kubectl is accessible"

# Step 2: Check metrics-server
echo ""
echo "✓ Checking metrics-server..."
if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
  echo "✓ metrics-server is deployed"
else
  echo "⚠️  metrics-server not found. HPA requires it. Install with:"
  echo "kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
fi

# Step 3: Create namespace
echo ""
echo "✓ Creating namespace '$NAMESPACE'..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace created"

# Step 4: Create deployment
echo ""
echo "✓ Creating deployment '$DEPLOYMENT'..."
kubectl create deployment $DEPLOYMENT --image=$IMAGE --replicas=2 -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Deployment created"

# Step 5: Add resource requests
echo ""
echo "✓ Adding CPU resource requests..."
kubectl set resources deployment $DEPLOYMENT --requests=cpu=$CPU_REQUEST -n $NAMESPACE
echo "✓ Resource requests added"

# Step 6: Apply HPA
echo ""
echo "✓ Applying HPA configuration..."
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $DEPLOYMENT
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $DEPLOYMENT
  minReplicas: 1
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
EOF
echo "✓ HPA deployed"

# Step 7: Verification
echo ""
echo "=================================="
echo "✓ Setup Complete!"
echo ""
echo "Status:"
kubectl get deployment -n $NAMESPACE
echo ""
kubectl get hpa -n $NAMESPACE
echo ""
echo "Next steps:"
echo "1. Wait 60-90s for metrics to populate"
echo "2. Check HPA targets: kubectl get hpa -n $NAMESPACE -w"
echo "3. Generate load: kubectl run -it load --image=busybox -n $NAMESPACE -- wget -q -O- http://$DEPLOYMENT"
echo "4. Watch scaling: kubectl get pods -n $NAMESPACE -w"
echo ""
echo "To cleanup:"
echo "kubectl delete namespace $NAMESPACE"
