#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="immich_machine_learning"

echo "Stoppe Container ‹${CONTAINER_NAME}›…"
docker stop "${CONTAINER_NAME}" || true

echo "Entferne Container ‹${CONTAINER_NAME}›…"
docker rm "${CONTAINER_NAME}" || true

echo "Fertig: Container gestoppt und gelöscht."
