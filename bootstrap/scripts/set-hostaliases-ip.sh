#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_FILE="${SCRIPT_DIR}/../argocd-values.yaml"

CLUSTER_IP="$(kubectl get svc traefik-internal-8443 -n kube-system -o jsonpath='{.spec.clusterIP}' 2>/dev/null)"

if [ -z "${CLUSTER_IP}" ]; then
  echo "error: traefik-internal-8443 Service not found (or has no ClusterIP yet) in kube-system" >&2
  echo "       apply infrastructure/traefik-internal-8443-service.yaml via Argo CD first" >&2
  exit 1
fi

sed -i "s/ip: \".*\"/ip: \"${CLUSTER_IP}\"/" "${VALUES_FILE}"
echo "Set hostAliases ip to ${CLUSTER_IP} in ${VALUES_FILE}"

if [ "${1:-}" = "--apply" ]; then
  helm upgrade argocd argo/argo-cd \
    --version 10.9.1 \
    --namespace argocd \
    --values "${VALUES_FILE}"
fi
