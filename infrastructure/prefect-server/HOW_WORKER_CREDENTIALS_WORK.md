# How Prefect Worker Credentials Work

## Overview

This document explains how Prefect worker jobs automatically use the ServiceAccount credentials we create, and why this fixes the `system:anonymous` authentication errors.

## The Complete Flow

### 1. **ServiceAccount Creation** (Manual Setup)
```bash
kubectl apply -f prefect-worker-rbac.yaml
```

This creates:
- `prefect-worker` ServiceAccount
- `prefect-worker-role` ClusterRole (with permissions)
- `prefect-worker-binding` ClusterRoleBinding (links ServiceAccount to permissions)

### 2. **Work Pool Configuration** (Manual Setup)
When you create or update your work pool, you specify the ServiceAccount:

```json
{
  "job": {
    "spec": {
      "template": {
        "spec": {
          "serviceAccountName": "prefect-worker",  // ← This is the key!
          "containers": [...]
        }
      }
    }
  }
}
```

### 3. **Worker Job Creation** (Automatic - Prefect does this)
When a flow needs to run, Prefect automatically creates a Kubernetes Job with this spec:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: prefect-job-xxxxx
spec:
  template:
    spec:
      serviceAccountName: prefect-worker  # ← Inherited from work pool config
      containers:
      - name: prefect-job
        image: gbifnorway/prefect-automations:latest
        command: ["prefect", "worker", "start"]
        # ... other config
```

### 4. **Kubernetes Authentication** (Automatic - Kubernetes does this)
When the worker pod starts:

1. **Kubernetes automatically mounts** the ServiceAccount token at `/var/run/secrets/kubernetes.io/serviceaccount/`
2. **The worker container automatically uses** this token for all Kubernetes API calls
3. **No code changes needed** - this is built into Kubernetes

## How the Worker "Knows" to Use the Credentials

### **Automatic Token Mounting**
Kubernetes automatically mounts the ServiceAccount token into every pod:

```bash
# Inside the worker pod, you'll find:
/var/run/secrets/kubernetes.io/serviceaccount/
├── ca.crt          # Cluster CA certificate
├── namespace       # Current namespace
└── token           # ServiceAccount JWT token
```

### **Automatic API Client Configuration**
When the Prefect worker makes Kubernetes API calls, it automatically:

1. **Detects the mounted token** (standard Kubernetes behavior)
2. **Uses the token for authentication** (no configuration needed)
3. **Gets the permissions** defined in the ClusterRole

### **No Code Changes Required**
The worker doesn't need to be told explicitly - this is all handled by:
- **Kubernetes** (token mounting)
- **Kubernetes client libraries** (automatic authentication)
- **Prefect's Kubernetes infrastructure** (uses standard Kubernetes patterns)

## Before vs After

### **Before (system:anonymous errors)**
```yaml
# Work pool config (missing or wrong ServiceAccount)
spec:
  template:
    spec:
      # No serviceAccountName specified
      containers: [...]
```

**Result**: Worker pod runs with `default` ServiceAccount (or none), gets `system:anonymous` permissions.

### **After (proper authentication)**
```yaml
# Work pool config (with correct ServiceAccount)
spec:
  template:
    spec:
      serviceAccountName: prefect-worker  # ← Specified here
      containers: [...]
```

**Result**: Worker pod runs with `prefect-worker` ServiceAccount, gets proper permissions.

## Verification Steps

### 1. **Check ServiceAccount exists**
```bash
kubectl get serviceaccount prefect-worker -n prefect
```

### 2. **Check permissions are bound**
```bash
kubectl get clusterrolebinding prefect-worker-binding
```

### 3. **Check worker job uses correct ServiceAccount**
```bash
# Get a recent worker job
kubectl get jobs -n prefect | grep prefect-job

# Check the job spec
kubectl get job <job-name> -n prefect -o yaml | grep -A 5 serviceAccountName
```

### 4. **Check worker pod has token mounted**
```bash
# Get the worker pod name
kubectl get pods -n prefect | grep prefect-job

# Check if token is mounted
kubectl exec <pod-name> -n prefect -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/
```

### 5. **Check logs for authentication errors**
```bash
# Check worker logs
kubectl logs <pod-name> -n prefect

# Should NOT see: "forbidden: User 'system:anonymous' cannot get path '/api'"
```

## Common Questions

### **Q: Do I need to modify the worker container image?**
**A: No!** The worker container doesn't need any changes. Kubernetes handles all the authentication automatically.

### **Q: What if I have multiple work pools?**
**A: You can use the same ServiceAccount** for all work pools, or create different ones for different permission levels.

### **Q: Can I use namespace-scoped permissions instead?**
**A: Yes!** The `prefect-worker-rbac.yaml` file includes commented-out Role/RoleBinding configurations for namespace-scoped access.

### **Q: What happens if the ServiceAccount doesn't exist?**
**A: The job will fail to start** with an error like "ServiceAccount 'prefect-worker' not found". This is actually good - it prevents the job from running with wrong permissions.

## Troubleshooting

### **Worker still shows system:anonymous errors**
1. Check that the work pool configuration has `"serviceAccountName": "prefect-worker"`
2. Verify the ServiceAccount exists: `kubectl get serviceaccount prefect-worker`
3. Check the ClusterRoleBinding: `kubectl get clusterrolebinding prefect-worker-binding`

### **Job fails to start**
1. Check if ServiceAccount exists: `kubectl get serviceaccount prefect-worker`
2. Check job events: `kubectl describe job <job-name> -n prefect`

### **Permission denied errors**
1. Check ClusterRole permissions: `kubectl get clusterrole prefect-worker-role -o yaml`
2. Verify the ClusterRoleBinding links the correct ServiceAccount and ClusterRole

## Summary

The worker "knows" to use the credentials through:

1. **Work pool configuration** specifies `serviceAccountName: prefect-worker`
2. **Kubernetes automatically mounts** the ServiceAccount token
3. **Kubernetes client libraries automatically use** the mounted token
4. **No code changes required** - it's all standard Kubernetes behavior

This is why the solution works seamlessly without any modifications to your worker container or Prefect code! 