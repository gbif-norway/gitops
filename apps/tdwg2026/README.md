## TDWG 2026 explorer on NIRD (`gbif-no-ns8095k`)

One container serves the static site and the `/api/search` endpoint. It needs no secrets, database or volume: the transcript data and embedding model are baked into the image.

- Image: `gbifnorway/tdwg2026` (built from `rukayaj/tdwg-2026-transcripts`)
- Deployment / Service: `tdwg2026` (port `80` -> `8787`)
- Ingress host: `tdwg2026.svc.gbif.no` (wildcard DNS, TLS via cert-manager like annotater)

### Deploy

From the app repo, `./scripts/deploy.sh` builds and pushes the image, pins the tag in `templates/deployment.yaml`, commits here, and applies the manifests. Manually:

```bash
kubectl --context nird-lmd -n gbif-no-ns8095k apply -f apps/tdwg2026/templates/
kubectl --context nird-lmd -n gbif-no-ns8095k rollout status deploy/tdwg2026
curl -I https://tdwg2026.svc.gbif.no/
```
