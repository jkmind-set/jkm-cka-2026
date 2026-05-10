#!/bin/bash

# CKA Practice: Kubelet Troubleshooting Guide
# Common kubelet issues and diagnostic commands for Docker Desktop

echo "🔧 CKA Practice: Kubelet Troubleshooting"
echo "========================================"
echo ""

# Function to display section headers
section() {
  echo ""
  echo "📍 $1"
  echo "---"
}

# 1. Check kubelet status
section "1. Kubelet Service Status"
echo "On Docker Desktop, kubelet runs inside the Docker Desktop VM."
echo "Commands to check kubelet:"
echo "  • kubectl get nodes -o wide"
echo "  • kubectl describe node <node-name>"
echo "  • kubectl get --raw /api/v1/nodes"

# 2. Node readiness
section "2. Check Node Readiness"
echo "List all nodes and their status:"
kubectl get nodes
echo ""
echo "Detailed node info:"
kubectl get nodes -o wide

# 3. Node conditions
section "3. Node Conditions & Status"
echo "Check for any NotReady conditions:"
kubectl describe nodes | grep -A 5 "Conditions:"

# 4. Kubelet logs
section "4. Access Kubelet Logs (Docker Desktop)"
echo "Docker Desktop kubelet logs:"
echo "  Option A (macOS/Linux with Docker Desktop):"
echo "    screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty"
echo ""
echo "  Option B: View kubelet service status"
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# 5. Common kubelet issues
section "5. Common Kubelet Issues on Docker Desktop"

echo "Issue: Nodes showing NotReady"
echo "  Solution:"
echo "    • Restart Docker Desktop: System Preferences → Docker → Restart"
echo "    • Check disk space: docker system df"
echo "    • Increase Docker resources: Docker Preferences → Resources"

echo ""
echo "Issue: Insufficient Memory"
echo "  Check: kubectl describe node | grep -A 3 'Allocatable'"
echo "  Fix: Increase Docker Desktop memory allocation"

echo ""
echo "Issue: Pod creation failures"
echo "  Check: kubectl get events -A"
echo "  Check: kubectl describe pod <pod-name> -n <namespace>"

# 6. Disk pressure
section "6. Check for Disk Pressure"
kubectl describe nodes | grep -A 3 "DiskPressure"

# 7. System pods status
section "7. System Pod Health (kube-system namespace)"
echo "Check all system pods are running:"
kubectl get pods -n kube-system

# 8. API Server connectivity
section "8. API Server Connectivity"
echo "Verify API server is accessible:"
kubectl get --raw /healthz
[ $? -eq 0 ] && echo "✓ API Server is healthy" || echo "❌ API Server issue detected"

# 9. CNI Status
section "9. Container Network Interface (CNI) Status"
echo "Docker Desktop uses Docker's built-in CNI. Check network plugins:"
kubectl get daemonset -n kube-system
echo ""
echo "Check CoreDNS for DNS resolution:"
kubectl get pods -n kube-system | grep coredns

# 10. Quick diagnostic summary
section "10. Complete System Diagnostic"
echo "Run this command for a complete cluster overview:"
echo "  kubectl cluster-info"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "  kubectl top nodes"
echo "  kubectl top pods -A"

echo ""
echo "========================================"
