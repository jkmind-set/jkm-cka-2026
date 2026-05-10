# Known Issues & Resolutions

This directory documents known issues encountered during CKA practice setup, their root causes, and the solutions applied.

## Issues Index

### 1. [kubectl Not Configured - Connection Refused](./kubectl-not-configured.md)

**Status:** ✅ RESOLVED  
**Severity:** High  
**Summary:** kubectl unable to connect to any Kubernetes cluster in dev container environment.

**Quick Fix:**
```bash
# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && \
chmod +x ./kind && \
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --name cka-practice

# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**Impact:** Blocked all practice until resolved. Now fully resolved with working cluster.

---

## How to Document New Issues

When encountering a new issue, create a new markdown file following this template:

```markdown
# Issue: [Brief Title]

**Date Reported:** [Date]
**Status:** 🟡 INVESTIGATING / ✅ RESOLVED / ❌ UNRESOLVED
**Severity:** Low / Medium / High / Critical
**Environment:** [Relevant details]

## Problem Description

[Clear description of the issue]

### Symptoms

[Error messages, unexpected behavior]

### Root Cause Analysis

[Investigation findings]

## Solution Implemented

[Step-by-step fix]

## Verification

[How to confirm the fix works]

## Notes

[Additional context or workarounds]
```

---

## Quick Reference

| Issue | Status | Quick Fix | Time to Fix |
|-------|--------|-----------|------------|
| kubectl not configured | ✅ Resolved | Install Kind, create cluster | ~5 min |

---

**Last Updated:** May 10, 2026  
**Total Issues:** 1 (1 Resolved, 0 Open)
