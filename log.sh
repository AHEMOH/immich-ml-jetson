#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="immich_machine_learning"

if [[ "${1:-}" == "clear" ]]; then
  echo "Leere Log-Datei von ‹${CONTAINER_NAME}›…"
  CID=$(docker inspect --format='{{.Id}}' "${CONTAINER_NAME}")
  sudo truncate -s 0 /var/lib/docker/containers/${CID}/${CID}-json.log
  echo "Logs geleert."
  exit 0
fi

echo "Zeige aktuelle Logs von ‹${CONTAINER_NAME}› (Strg-C zum Beenden)…"
docker logs --tail 100 -f "${CONTAINER_NAME}"
