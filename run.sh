#!/usr/bin/env bash
set -euo pipefail

# 0. Konfiguration
IMAGE_NAME="immich-ml-jetson:latest"
CONTAINER_NAME="immich_machine_learning"
PROJECT_DIR="$HOME/immich-ml-jetson"
CACHE_DIR="$PROJECT_DIR/cache"

# 1. Umgebungsvariablen
export TRANSFORMERS_CACHE="$CACHE_DIR"
export TORCH_HOME="$CACHE_DIR"
export DEVICE="cuda"
export MACHINE_LEARNING_DEVICE_IDS="0"
export MACHINE_LEARNING_WORKERS="1"
export IMMICH_VERSION="release"

# 2. Cache-Verzeichnis anlegen
mkdir -p "$CACHE_DIR"

# 3. Vor-Check: Docker GPU-Zugriff
echo "Prüfe GPU-Zugriff via nvidia-smi..."
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi || {
  echo "Fehler: Keine GPU in Docker erreichbar!" >&2
  exit 1
}

# 4. Vor-Check: Container-Inferenz-Test (ONNX + Torch)
echo "Prüfe ONNX und Torch im Image..."
docker run --rm --gpus all \
  "$IMAGE_NAME" \
  python3 - <<'EOF'
import torch, onnxruntime as ort
assert torch.cuda.is_available(), "Torch CUDA nicht verfügbar"
providers = ort.get_all_providers()
assert "CUDAExecutionProvider" in providers, f"Kein CUDA-Provider in ONNX: {providers}"
print("Vor-Check OK: Torch & ONNX GPU verfügbar")
EOF

# 5. Alten Container entfernen (falls vorhanden)
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stoppe und entferne alten Container ${CONTAINER_NAME}..."
  docker stop "${CONTAINER_NAME}" || true
  docker rm    "${CONTAINER_NAME}" || true
fi

# 6. Container starten
echo "Starte Container ${CONTAINER_NAME}..."
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

# 7. Post-Check: Dienst-Health und GPU-Log
echo "Warte 5 Sekunden auf Dienststart..."
sleep 5

echo "Prüfe Health-Endpunkt..."
if curl -sf http://localhost:3003/ping >/dev/null; then
  echo "Health OK"
else
  echo "Health-Check fehlgeschlagen" >&2
  exit 1
fi

echo "Prüfe GPU-Nutzung im Container (nvidia-smi) ..."
docker exec "${CONTAINER_NAME}" nvidia-smi || {
  echo "Fehler: nvidia-smi im Container fehlgeschlagen" >&2
  exit 1
}

echo "Container ${CONTAINER_NAME} läuft mit GPU-Unterstützung auf Port 3003."
