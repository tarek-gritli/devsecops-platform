#!/usr/bin/env bash
set -euo pipefail

# Bootstraps a fresh k3d cluster (after `terraform apply`) up to the point
# where Argo CD's app-of-apps takes over and everything else syncs itself.
# Safe to re-run — every step is idempotent.
#
# Prerequisites this script does NOT create (see bootstrap/README.md):
#   - `terraform apply` already run (cluster + Traefik exist)
#   - local-certs/local.crt, local-certs/local.key (from the openssl CA/cert steps)
#   - age-key.txt (from `age-keygen`)
#   - /etc/hosts has the three .local hostnames
#   - k3d, helm, kubectl on PATH; `helm repo add argo https://argoproj.github.io/argo-helm` already done

cd "$(git rev-parse --show-toplevel)"

for f in local-certs/local.crt local-certs/local.key age-key.txt; do
  if [ ! -f "$f" ]; then
    echo "error: $f not found — this can't be regenerated, see bootstrap/README.md" >&2
    exit 1
  fi
done

echo "==> Installing Argo CD"
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --version 10.9.1 \
  --namespace argocd \
  --create-namespace \
  --values bootstrap/argocd-values.yaml \
  --wait

echo "==> Creating namespaces for out-of-band secrets"
for ns in demo-app-dev keycloak; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "==> Creating TLS secrets (from local-certs/, never committed)"
for pair in "demo-app-tls:demo-app-dev" "keycloak-tls:keycloak" "argocd-tls:argocd"; do
  name="${pair%%:*}"
  ns="${pair##*:}"
  kubectl create secret tls "$name" \
    --cert=local-certs/local.crt --key=local-certs/local.key \
    -n "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "==> Creating the age private key secret (from age-key.txt, never committed)"
kubectl create secret generic sops-age-key \
  --namespace argocd \
  --from-file=keys.txt=age-key.txt \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Applying the root app-of-apps (the one manual kubectl apply, by design)"
kubectl apply -f bootstrap/root-app.yaml

echo "==> Waiting for infrastructure to sync and Traefik's internal 8443 Service to exist"
until kubectl get svc traefik-internal-8443 -n kube-system >/dev/null 2>&1; do
  sleep 5
done

echo "==> Fixing the hostAliases ClusterIP (always different on a fresh cluster) and re-applying"
./bootstrap/scripts/set-hostaliases-ip.sh --apply

echo "==> Done. Check: kubectl get applications -n argocd"
