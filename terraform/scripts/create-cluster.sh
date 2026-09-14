#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:?cluster name is required}"
SERVERS="${2:?servers count is required}"
AGENTS="${3:?agents count is required}"
API_PORT="${4:?api port is required}"
HTTP_PORT="${5:?http port is required}"
HTTPS_PORT="${6:?https port is required}"

if k3d cluster get "${CLUSTER_NAME}" >/dev/null 2>&1; then
  echo "Cluster ${CLUSTER_NAME} already exists"
  exit 0
fi

k3d cluster create "${CLUSTER_NAME}" \
  --servers "${SERVERS}" \
  --agents "${AGENTS}" \
  --api-port "${API_PORT}" \
  --port "${HTTP_PORT}:80@loadbalancer" \
  --port "${HTTPS_PORT}:443@loadbalancer" \
  --wait \
  --timeout 120s