# GBIF Norway App Deploy Docs (NIRD)

This repository stores Kubernetes/Helm definitions used by GBIF Norway apps.

For current NIRD operations, deployments are intentionally simple and command-driven.
Argo CD may exist in the cluster, but it is not required for routine deployment of the app set below.

## Target Cluster

- Context: `nird-lmd`
- Namespace: `gbif-no-ns8095k`

## App Deployment Model (Current)

1. `chatipt` and `chatipt-staging`: Helm releases from this repo.
2. `annotater`: static Kubernetes manifests from this repo.
3. `ipt` deployments (`main/corema/slovakia/ukraine`): maintained in `ipt-s3` repo (`k8s/nird`).
4. `resolver`: maintained in `resolver-docker` repo (`k8s/nird`).

## Deploy Commands

### ChatIPT (prod + staging)

```bash
helm upgrade --install chatipt /Users/rukayasj/Projects/gitops/apps/chatipt \
  -n gbif-no-ns8095k \
  -f /Users/rukayasj/Projects/gitops/apps/chatipt/values-prod.yaml

helm upgrade --install chatipt-staging /Users/rukayasj/Projects/gitops/apps/chatipt \
  -n gbif-no-ns8095k \
  -f /Users/rukayasj/Projects/gitops/apps/chatipt/values-staging.yaml
```

### Annotater

```bash
kubectl --context nird-lmd -n gbif-no-ns8095k apply -f /Users/rukayasj/Projects/gitops/apps/annotater/templates/deployment.yml
kubectl --context nird-lmd -n gbif-no-ns8095k apply -f /Users/rukayasj/Projects/gitops/apps/annotater/templates/service.yaml
kubectl --context nird-lmd -n gbif-no-ns8095k apply -f /Users/rukayasj/Projects/gitops/apps/annotater/templates/ingress.yaml
```

### IPTs

See:

- `/Users/rukayasj/Projects/ipt-s3/README.md`

### Resolver

See:

- `/Users/rukayasj/Projects/resolver-docker/k8s/nird/README.md`

## Verify Rollouts

```bash
kubectl --context nird-lmd -n gbif-no-ns8095k get deploy
kubectl --context nird-lmd -n gbif-no-ns8095k get ingress
```
