# Issue: kubectl Not Configured - Connection Refused

**Date Reported:** May 10, 2026  
**Status:** ✅ RESOLVED  
**Severity:** High (blocks all practice)  
**Environment:** Dev Container (Ubuntu 24.04.4 LTS) with Docker Desktop

---

## Problem Description

When attempting to run HPA practice scripts in the dev container, kubectl was unable to connect to any Kubernetes cluster.

### Symptoms

```bash
❌ kubectl not accessible. Ensure Docker Desktop Kubernetes is enabled.

kubectl get nodes
E0510 13:40:34.331510    7099 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp [::1]:8080: connect: connection refused"
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

### Root Cause Analysis

1. **Empty kubeconfig** - Running `kubectl config view` returned:
   ```yaml
   apiVersion: v1
   clusters: null
   contexts: null
   current-context: ""
   users: null
   ```

2. **Missing kubeconfig file** - No configuration file at `~/.kube/config`

3. **Environmental mismatch** - The dev container environment (inside Docker Desktop) cannot directly access the host's Docker Desktop Kubernetes cluster. The container needed its own isolated Kubernetes cluster for practice.

---

## Solution Implemented

### Step 1: Install Kind (Kubernetes in Docker)

**Command:**
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
chmod +x ./kind && \
sudo mv ./kind /usr/local/bin/kind
```

**Rationale:** Kind allows running a complete Kubernetes cluster inside Docker, making it ideal for dev containers and isolated test environments.

### Step 2: Create a Kubernetes Cluster

**Command:**
```bash
kind create cluster --name cka-practice
```

**Output:**
```
Creating cluster "cka-practice" ...
 ✓ Ensuring node image (kindest/node:v1.35.1)
 ✓ Preparing nodes
 ✓ Writing configuration
 ✓ Starting control-plane
 ✓ Installing CNI
 ✓ Installing StorageClass
Set kubectl context to "kind-cka-practice"
```

**What was created:**
- Single-node Kubernetes cluster (v1.35.1)
- Auto-configured kubeconfig at `~/.kube/config`
- CNI (Container Network Interface) for pod networking
- StorageClass for persistent volumes

### Step 3: Verify Cluster Status

**Command:**
```bash
kubectl cluster-info
kubectl get nodes
```

**Expected Result:**
```
Kubernetes control plane is running at https://127.0.0.1:34747
CoreDNS is running at https://127.0.0.1:34747/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

NAME                         STATUS   ROLES           AGE   VERSION
cka-practice-control-plane   Ready    control-plane   40s   v1.35.1
```

### Step 4: Install Metrics Server

**Command:**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**Rationale:** Metrics Server is required for HPA to collect and report CPU/Memory metrics from pods. Without it, HPA cannot make scaling decisions.

**Verification:**
```bash
kubectl get pods -n kube-system | grep metrics-server
metrics-server-XXXXX                        1/1     Running
```

---

## Verification of Fix

### Test Command
```bash
./setup-hpa-practice.sh
```

### Expected Output
```
🚀 CKA Practice: HPA Setup Script
==================================
✓ Verifying kubectl connection...
✓ kubectl is accessible
✓ Checking metrics-server...
✓ metrics-server is deployed
✓ Creating namespace 'autoscale'...
✓ Namespace created
✓ Creating deployment 'apache-server'...
✓ Deployment created
✓ Adding CPU resource requests...
✓ Resource requests added
✓ Applying HPA configuration...
✓ HPA deployed
```

### Configuration Validation
All HPA settings verified:
- ✅ MinReplicas: 1
- ✅ MaxReplicas: 4
- ✅ CPU Target Utilization: 50%
- ✅ Downscale Stabilization Window: 30s
- ✅ Deployment pods: Running

---

## How This Affects Future Practice

### What Changed

| Before | After |
|--------|-------|
| ❌ No kubectl access | ✅ Full kubectl access |
| ❌ No kubeconfig | ✅ Auto-configured at ~/.kube/config |
| ❌ Cannot practice HPA | ✅ Complete HPA environment ready |
| ❌ No metrics collection | ✅ Metrics Server deployed |

### How to Use Going Forward

```bash
# Start a new practice session
cd /workspaces/jkm-cka-2026/scenarios
./setup-hpa-practice.sh      # Sets up HPA environment
./validate-hpa.sh            # Validates configuration
./troubleshooting-kubelet.sh # Kubelet diagnostics

# Monitor HPA scaling
kubectl get hpa -n autoscale -w

# Generate load to test scaling
kubectl run -it load --image=busybox -n autoscale -- sh
# Inside container: while true; do wget -q -O- http://apache-server; done
```

---

## Notes for Future

- **Cluster persistence**: The Kind cluster persists across terminal sessions until explicitly deleted
- **Clean up**: To remove the practice cluster: `kind delete cluster --name cka-practice`
- **Multiple clusters**: Can create multiple clusters (e.g., `kind create cluster --name cka-advanced`)
- **Container registry**: Kind can load local Docker images with: `kind load docker-image IMAGE --name cka-practice`

---

## Related Documents

- [PRACTICE_GUIDE.md](../PRACTICE_GUIDE.md) - Complete HPA practice walkthrough
- [setup-hpa-practice.sh](../scenarios/setup-hpa-practice.sh) - Automated environment setup
- [validate-hpa.sh](../scenarios/validate-hpa.sh) - Configuration validator
- [troubleshooting-kubelet.sh](../scenarios/troubleshooting-kubelet.sh) - Diagnostics script
