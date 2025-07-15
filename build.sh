#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="immich-ml-jetson:latest"
DOCKERFILE="Dockerfile"

echo "Baue Docker-Image ‹${IMAGE_NAME}› aus ‹${DOCKERFILE}›…"
docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE}" .
echo "Fertig: Image ${IMAGE_NAME}"
