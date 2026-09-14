#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:?cluster name required}"

if k3d cluster get "${CLUSTER_NAME}" >/dev/null 2>&1; then
  k3d cluster delete "${CLUSTER_NAME}"
else
  echo "k3d cluster '${CLUSTER_NAME}' does not exist, skipping delete"
fi