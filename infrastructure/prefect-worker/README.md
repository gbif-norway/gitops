# Prefect Worker Deployment

This directory contains the Kubernetes deployment for the Prefect worker that processes jobs from the `gbif-automations` work pool.

## Architecture

- **Custom Container**: Uses `gbifnorway/prefect-automations:latest` which contains:
  - Your flow code
  - All dependencies
  - Prefect runtime
- **Work Pool**: Connects to `gbif-automations` Kubernetes work pool
- **Service Account**: Uses existing `prefect-worker` service account with proper RBAC

## Setup

### 1. Create Prefect API Key Secret

You need to create the API key secret before deploying:

```bash
# Generate a Prefect API key (if you don't have one)
prefect api-key create worker-key

# Create the secret (replace with your actual API key)
kubectl create secret generic prefect-api-key \
  --from-literal=api-key="your-api-key-here" \
  -n prefect
```

### 2. Deploy with ArgoCD

Create an ArgoCD application for this worker:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prefect-worker
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main
    path: gitops/infrastructure/prefect-worker
  destination:
    server: https://kubernetes.default.svc
    namespace: prefect
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Custom Container Best Practices

✅ **Include in your container**:
- Flow code (`src/automations/flows/`)
- Dependencies (`pyproject.toml`, `requirements.txt`)
- Prefect runtime
- Any custom utilities

✅ **Benefits**:
- Reproducible environments
- No dependency conflicts
- Faster job startup
- Tested in CI/CD

## Monitoring

Check worker status:
```bash
kubectl get pods -n prefect -l app=prefect-worker
kubectl logs -n prefect -l app=prefect-worker -f
```

## Scaling

To scale the worker:
```bash
kubectl scale deployment prefect-worker --replicas=2 -n prefect
```

## Troubleshooting

1. **Worker not starting**: Check API key secret
2. **Jobs not being picked up**: Verify work pool configuration
3. **Authentication errors**: Check service account permissions 