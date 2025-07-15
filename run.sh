#!/usr/bin/env bash
set -euo pipefail

# Name des Images und Containers
IMAGE_NAME="immich-ml-jetson:latest"
CONTAINER_NAME="immich_machine_learning"

# Umgebungsvariablen (kannst du anpassen oder aus .env laden)
export TRANSFORMERS_CACHE="/home/jetson/immich-ml-jetson/cache"
export TORCH_HOME="/home/jetson/immich-ml-jetson/cache"
export DEVICE="cuda"
export MACHINE_LEARNING_DEVICE_IDS="0"
export MACHINE_LEARNING_WORKERS="1"
export IMMICH_VERSION="release"

# Projekt-Verzeichnis anpassen
PROJECT_DIR="$HOME/immich-ml-jetson"
CACHE_DIR="$PROJECT_DIR/cache"

# Cache-Ordner anlegen
mkdir -p "$CACHE_DIR"

# Bestehenden Container stoppen und löschen (falls vorhanden)
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stoppe und entferne alten Container ${CONTAINER_NAME}..."
  docker stop "${CONTAINER_NAME}" || true
  docker rm    "${CONTAINER_NAME}" || true
fi

# Container starten mit GPU-Sharing und automatischem Neustart
docker run -d \
  --name "${CONTAINER_NAME}" \
  --gpus all \
  --restart unless-stopped \
  -p 3003:3003 \
  -v "${CACHE_DIR}:/cache" \
  -e TRANSFORMERS_CACHE="/cache" \
  -e TORCH_HOME="/cache" \
  -e DEVICE="${DEVICE}" \
  -e MACHINE_LEARNING_DEVICE_IDS="${MACHINE_LEARNING_DEVICE_IDS}" \
  -e MACHINE_LEARNING_WORKERS="${MACHINE_LEARNING_WORKERS}" \
  -e IMMICH_VERSION="${IMMICH_VERSION}" \
  "${IMAGE_NAME}"

echo "Container ${CONTAINER_NAME} läuft jetzt. Port 3003 → Host 3003"
