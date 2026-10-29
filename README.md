# GBIF Norway App Deploy Docs (NIRD)

This repository stores Kubernetes/Helm definitions used by GBIF Norway apps.

For current NIRD operations, deployments are intentionally simple and command-driven.
Argo CD may exist in the cluster, but it is not required for routine deployment of the app set below.

## Target Cluster

- Context: `nird-lmd`
- Namespace: `gbif-no-ns8095k`

## App Deployment Model (Current)

1. `chatipt`: Helm release from this repo (there is no staging release since 2026-10-26).
2. `annotater`: static Kubernetes manifests from this repo.
3. `ipt` deployments (`main/corema/slovakia/ukraine`): maintained in `ipt-s3` repo (`k8s/nird`).
4. `resolver`: maintained in `resolver-docker` repo (`k8s/nird`).

## Deploy Commands

### ChatIPT

ChatIPT's GitHub Actions workflow builds and publishes both images on pushes to
`main`. Once the whole workflow succeeds, copy the deployment command from its
summary and run it from the application checkout:

```bash
cd /Users/rukayasj/Projects/chatipt
./scripts/deploy-prod.sh --tag sha-FULL_COMMIT_SHA
```

Replace `FULL_COMMIT_SHA` with the full commit hash from that successful build.
The script verifies both images exist, updates this repository's
`apps/chatipt/values-prod.yaml`, commits and pushes the values, deploys with Helm,
and checks the rollout. It does not build or push images. GitHub pushes alone do
not deploy production. For full instructions, see `../chatipt/DEPLOYMENT.md`.
There is no staging release.

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
