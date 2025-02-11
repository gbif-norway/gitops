# GitOps-infrastucture

## Install Argo CD

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd
```

## Install Argo CD CLI

```bash
brew install argocd
```

## Access Argo CD

To access Argo CD, you'll need to:

2. Login using the CLI:
```bash
argocd login argocd.svc.gbif.no:443
```