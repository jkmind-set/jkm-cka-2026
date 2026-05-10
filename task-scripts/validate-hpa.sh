#!/bin/bash

# CKA Practice: HPA Validation Script
# Validates that HPA is correctly configured for the autoscale namespace

NAMESPACE="autoscale"
HPA_NAME="apache-server"

echo "🔍 CKA Practice: HPA Validation Script"
echo "======================================"
echo ""

# Check if HPA exists
if ! kubectl get hpa $HPA_NAME -n $NAMESPACE &> /dev/null; then
  echo "❌ HPA '$HPA_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

echo "✓ HPA '$HPA_NAME' exists in namespace '$NAMESPACE'"
echo ""

# Get HPA details
echo "📊 HPA Configuration:"
echo "--------------------"
kubectl get hpa $HPA_NAME -n $NAMESPACE -o wide
echo ""

# Describe HPA for full details
echo "📋 HPA Details:"
echo "---------------"
kubectl describe hpa $HPA_NAME -n $NAMESPACE
echo ""

# Check metrics status
TARGETS=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.status.currentMetrics}')
if [ -z "$TARGETS" ] || [ "$TARGETS" == "[]" ]; then
  echo "⚠️  No metrics available yet (still loading...)"
  echo "   Wait 60-90 seconds for metrics-server to collect data"
else
  echo "✓ Metrics are available:"
  kubectl get hpa $HPA_NAME -n $NAMESPACE -o json | jq '.status.currentMetrics'
fi
echo ""

# Validate configuration requirements
echo "✅ Configuration Validation:"
echo "--------------------------"

# Check minReplicas
MIN_REPLICAS=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.spec.minReplicas}')
echo "MinReplicas: $MIN_REPLICAS (expected: 1)"
[ "$MIN_REPLICAS" == "1" ] && echo "✓ Pass" || echo "❌ FAIL"
echo ""

# Check maxReplicas
MAX_REPLICAS=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.spec.maxReplicas}')
echo "MaxReplicas: $MAX_REPLICAS (expected: 4)"
[ "$MAX_REPLICAS" == "4" ] && echo "✓ Pass" || echo "❌ FAIL"
echo ""

# Check CPU target
CPU_TARGET=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}')
echo "CPU Target Utilization: $CPU_TARGET% (expected: 50)"
[ "$CPU_TARGET" == "50" ] && echo "✓ Pass" || echo "❌ FAIL"
echo ""

# Check stabilization window
STABIL_WINDOW=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}')
echo "Downscale Stabilization Window: ${STABIL_WINDOW}s (expected: 30)"
[ "$STABIL_WINDOW" == "30" ] && echo "✓ Pass" || echo "❌ FAIL"
echo ""

echo "======================================"
echo "Validation complete!"
echo ""
echo "Deployment Status:"
kubectl get deployment apache-server -n $NAMESPACE
echo ""
echo "Current Pods:"
kubectl get pods -n $NAMESPACE
