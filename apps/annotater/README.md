## Annotater on NIRD (`gbif-no-ns8095k`)

This app is deployed as:
- Deployment: `annotater-web`
- Service: `annotater-web` (port `80` -> target port `8080`)
- Ingress host: `annotater.svc.gbif.no`
- Ingress class: `nginx`
- TLS secret: `annotater-web-tls`

### Database setup

Annotater uses the `annotater-env` secret (via `envFrom`) for DB config:
- `SQL_ENGINE`
- `SQL_HOST`
- `SQL_PORT`
- `SQL_DATABASE`
- `SQL_USER`
- `SQL_PASSWORD`

Current intended host is NIRD shared Postgres service:
- `postgres-shared.gbif-no-ns8095k.svc.cluster.local:5432`

### TLS setup

TLS is issued automatically by cert-manager through ingress annotations:
- `kubernetes.io/ingress.class: nginx`
- `kubernetes.io/tls-acme: "true"`

Ingress TLS block references:
- `secretName: annotater-web-tls`

### Deploy / apply

These manifests are static and can be applied directly:

```bash
kubectl --context nird-lmd -n gbif-no-ns8095k apply -f apps/annotater/templates/deployment.yml
kubectl --context nird-lmd -n gbif-no-ns8095k apply -f apps/annotater/templates/service.yaml
kubectl --context nird-lmd -n gbif-no-ns8095k apply -f apps/annotater/templates/ingress.yaml
```

### Verify

```bash
kubectl --context nird-lmd -n gbif-no-ns8095k get deploy,svc,ingress | grep annotater
kubectl --context nird-lmd -n gbif-no-ns8095k get secret annotater-web-tls
curl -I https://annotater.svc.gbif.no/
```

Expected HTTPS result:
- valid Let's Encrypt certificate for `annotater.svc.gbif.no`
- `HTTP/2 200` from the app

### When NIRD platform admins may need to help

Only if one of these is missing:
- DNS for `annotater.svc.gbif.no` does not resolve to NIRD ingress IP (`158.36.102.245`)
- cert-manager / ACME issuance is failing in cluster
