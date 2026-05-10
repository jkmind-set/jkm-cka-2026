# CKA Practice Guide - Using Docker Desktop Kubeadmin Node

## Environment Setup

### Prerequisites
- Docker Desktop with Kubernetes enabled
- `kubectl` configured and accessible
- `metrics-server` deployed (required for HPA to work)

### Verify Your Setup
```bash
# Check cluster access
kubectl cluster-info
kubectl get nodes

# Verify metrics-server is running (required for HPA)
kubectl get deployment metrics-server -n kube-system
```

---

## Practice: Horizontal Pod Autoscaler (HPA)

### Step 1: Create Practice Namespace & Deployment
```bash
# Create namespace
kubectl create namespace autoscale

# Create a test deployment with CPU requests
kubectl create deployment apache-server \
  --image=httpd:2.4 \
  --replicas=2 \
  -n autoscale

# Add resource requests so HPA can calculate CPU utilization
kubectl set resources deployment apache-server \
  --requests=cpu=100m \
  -n autoscale
```

### Step 2: Apply HPA Configuration
```bash
# Create HPA with advanced behavior settings
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apache-server
  namespace: autoscale
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apache-server
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
```

### Step 3: Validation & Monitoring
```bash
# Check HPA status
kubectl get hpa -n autoscale
kubectl describe hpa apache-server -n autoscale

# Watch real-time scaling (in separate terminal)
kubectl get hpa -n autoscale -w

# Monitor pod replicas
kubectl get pods -n autoscale -w
```

### Step 4: Generate Load (Test Scaling)
```bash
# Create a load generator pod
kubectl run -it load-generator --image=busybox -n autoscale -- /bin/sh

# Inside the container, run:
# while true; do wget -q -O- http://apache-server; done
```

---

## Quick Reference: Common CKA HPA Tasks

| Task | Command |
|------|---------|
| Create basic HPA | `kubectl autoscale deployment NAME --cpu-percent=80 --min=1 --max=10` |
| Get HPA details | `kubectl describe hpa NAME -n NAMESPACE` |
| Edit HPA | `kubectl edit hpa NAME -n NAMESPACE` |
| Delete HPA | `kubectl delete hpa NAME -n NAMESPACE` |
| Check scaling metrics | `kubectl get hpa -n NAMESPACE -o wide` |

---

## Troubleshooting

**HPA shows `<unknown>` in Targets column:**
- Ensure `metrics-server` is deployed
- Wait 60-90 seconds for metrics to populate
- Pods must have CPU requests defined

**Pods not scaling:**
- Check HPA status: `kubectl describe hpa NAME`
- Verify CPU requests on deployment
- Ensure adequate load/traffic

---

## Next Steps
- Practice threshold adjustments (change CPU% from 50% to different values)
- Test scale-down behavior with stabilization windows
- Experiment with memory-based HPA metrics
- Explore custom metrics HPAs
