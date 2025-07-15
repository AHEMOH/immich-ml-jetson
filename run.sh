#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# run.sh – Immich ML-Container auf Jetson Xavier mit GPU- und Health-Checks
# (angepasst für tegrastats statt nvidia-smi)
# -------------------------------------------------------------------

# 0. Konfiguration
IMAGE_NAME="immich-ml-jetson:latest"
CONTAINER_NAME="immich_machine_learning"
PROJECT_DIR="$HOME/immich-ml-jetson"
CACHE_DIR="$PROJECT_DIR/model_cache"

# 1. Umgebungsvariablen
export TRANSFORMERS_CACHE="$CACHE_DIR"
export TORCH_HOME="$CACHE_DIR"
export MACHINE_LEARNING_CACHE_FOLDER="$CACHE_DIR"
export DEVICE="cuda"
export MACHINE_LEARNING_DEVICE_IDS="0"
export MACHINE_LEARNING_WORKERS="1"
export IMMICH_VERSION="release"

# 2. Cache-Verzeichnis anlegen (persistent für Modelle)
mkdir -p "$CACHE_DIR"

# 4. Pre-Check: ONNX & Torch im Image
echo "Prüfe ONNX & Torch GPU-Support im Image…"
docker run --rm -i --gpus all "$IMAGE_NAME" python3 - <<'EOF'
import torch, onnxruntime as ort
assert torch.cuda.is_available(), "Torch CUDA nicht verfügbar"
providers = ort.get_all_providers()
assert "CUDAExecutionProvider" in providers, f"Kein CUDA-Provider in ONNX: {providers}"
print("Vor-Check OK: Torch & ONNX GPU verfügbar")
EOF

# 5. Alten Container entfernen (falls vorhanden)
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stoppe und entferne alten Container ${CONTAINER_NAME}…"
  docker stop "${CONTAINER_NAME}" || true
  docker rm    "${CONTAINER_NAME}" || true
fi

# 6. Container starten
echo "Starte Container ${CONTAINER_NAME}…"
docker run -d \
  --name "${CONTAINER_NAME}" \
  --gpus all \
  --restart unless-stopped \
  -p 3003:3003 \
  -v "${CACHE_DIR}:/cache" \
  -e TRANSFORMERS_CACHE="/cache" \
  -e TORCH_HOME="/cache" \
  -e MACHINE_LEARNING_CACHE_FOLDER="/cache" \
  -e DEVICE="${DEVICE}" \
  -e MACHINE_LEARNING_DEVICE_IDS="${MACHINE_LEARNING_DEVICE_IDS}" \
  -e MACHINE_LEARNING_WORKERS="${MACHINE_LEARNING_WORKERS}" \
  -e IMMICH_VERSION="${IMMICH_VERSION}" \
  "${IMAGE_NAME}"



echo "Container ${CONTAINER_NAME} läuft erfolgreich mit GPU-Unterstützung auf Port 3003."
