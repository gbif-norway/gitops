# 🔧 DevOps Request: Fix Prefect Worker Kubernetes Permissions

## **Issue Summary**

The Prefect worker jobs are running with insufficient Kubernetes permissions, causing authentication errors in the logs. While flows are executing successfully, the worker is generating noise in logs due to `system:anonymous` user permissions.

### **Current Error Pattern:**
```
forbidden: User "system:anonymous" cannot get path "/api"
forbidden: User "system:anonymous" cannot get path "/apis"
```

### **Root Cause:**
Prefect worker jobs are being created dynamically but are not using a properly configured ServiceAccount with the necessary RBAC permissions. The jobs are falling back to `system:anonymous` authentication.

## **Solution Overview**

We need to create a dedicated ServiceAccount for Prefect worker jobs with appropriate RBAC permissions, then update the work pool configuration to use this ServiceAccount.

## **Implementation Steps**

### **Step 1: Apply RBAC Configuration**

Apply the provided `prefect-worker-rbac.yaml` file:

```bash
# Update the namespace in the file if needed, then apply
kubectl apply -f prefect-worker-rbac.yaml
```

This creates:
- `prefect-worker` ServiceAccount
- `prefect-worker-role` ClusterRole with comprehensive permissions
- `prefect-worker-binding` ClusterRoleBinding

### **Step 2: Update Work Pool Configuration**

Update your Prefect work pool configuration to use the new ServiceAccount:

**Before:**
```json
{
  "serviceAccountName": "prefect-server"
}
```

**After:**
```json
{
  "serviceAccountName": "prefect-worker"
}
```

### **Step 3: Verify Configuration**

1. Check that the ServiceAccount exists:
   ```bash
   kubectl get serviceaccount prefect-worker -n <namespace>
   ```

2. Verify the ClusterRole and ClusterRoleBinding:
   ```bash
   kubectl get clusterrole prefect-worker-role
   kubectl get clusterrolebinding prefect-worker-binding
   ```

3. Test with a new flow run to confirm no more authentication errors.

## **Files Modified/Created**

### **New Files:**
- `prefect-worker-rbac.yaml` - RBAC configuration for worker permissions
- `DEVOPS_REQUEST_PREFECT_WORKER_RBAC.md` - This request document

### **Updated Files:**
- `INFRASTRUCTURE_WORK_POOLS.md` - Updated to use `prefect-worker` ServiceAccount

## **RBAC Permissions Included**

The `prefect-worker-role` ClusterRole includes permissions for:

- **Core Resources**: pods, services, configmaps, secrets, events, namespaces
- **Apps Resources**: deployments, statefulsets, daemonsets, replicasets
- **Batch Resources**: jobs, cronjobs
- **Networking**: networkpolicies, ingresses
- **Storage**: persistentvolumeclaims, persistentvolumes
- **RBAC**: roles, rolebindings, clusterroles, clusterrolebindings (read-only)
- **API Discovery**: api, apis (for Kubernetes API discovery)

## **Alternative: Namespace-Scoped Permissions**

If you prefer to limit worker permissions to a specific namespace, the `prefect-worker-rbac.yaml` file includes commented-out Role and RoleBinding configurations that provide namespace-scoped access instead of cluster-wide permissions.

## **Priority & Impact**

- **Priority**: Low (flows are working correctly)
- **Purpose**: Clean up log noise and improve monitoring
- **Risk**: Low (additive changes only)
- **Rollback**: Easy (can revert to `prefect-server` ServiceAccount if needed)

## **Expected Results**

After applying these changes:

1. ✅ No more `system:anonymous` authentication errors in logs
2. ✅ Cleaner, more readable logs
3. ✅ Proper Kubernetes API access for worker jobs
4. ✅ Maintained functionality (flows continue to work)
5. ✅ Better security posture with dedicated worker permissions

## **Testing**

To verify the fix:

1. Apply the RBAC configuration
2. Update work pool configuration
3. Trigger a new flow run
4. Check logs for absence of authentication errors
5. Verify flow execution continues to work normally

## **Monitoring**

After implementation, monitor:

- Log noise reduction
- Flow execution success rates
- Any new permission-related errors
- Worker job creation and cleanup

## **Notes**

- The `prefect-server` ServiceAccount remains unchanged and continues to serve the Prefect server itself
- Worker jobs now have their own dedicated ServiceAccount with appropriate permissions
- This change is backward compatible and can be easily rolled back if needed
- Consider reviewing the permissions periodically to ensure they match your security requirements

---

**Contact**: DevOps Team  
**Date**: [Current Date]  
**Status**: Ready for Implementation 