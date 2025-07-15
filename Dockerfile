# -------------------------------------------------------------------
# Dockerfile für Immich ML auf Jetson Xavier (JetPack 5.x + Python 3.10)
# Basis: balenalib/jetson-xavier-nx-devkit-ubuntu-python:3.10-latest-build
# -------------------------------------------------------------------

# 1. Optimiertes Base-Image mit Ubuntu + Python 3.10 auf ARM64
FROM balenalib/jetson-xavier-nx-devkit-ubuntu-python:3.10-latest-build

# 1. Noninteractive Modus aktivieren
ENV DEBIAN_FRONTEND=noninteractive
# 2. Zeitzone setzen
ENV TZ=Europe/Berlin

# 3. tzdata installieren ohne Prompt
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*


# 2. Systemabhängigkeiten installieren
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      protobuf-compiler \
      libprotobuf-dev \
      python3-opencv && \
    rm -rf /var/lib/apt/lists/*

# 3. Pip-Tools aktualisieren
RUN python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir

# 4. Aiocache aus Git installieren (ohne Build-Isolation)
RUN pip3 install --no-build-isolation --no-cache-dir \
    "git+https://github.com/aio-libs/aiocache.git@v0.12.3#egg=aiocache"

# 5. Framework- und Utility-Pakete von PyPI installieren
RUN pip3 install --no-cache-dir \
    "pydantic-settings>=2.5.2,<3" \
    rich \
    fastapi \
    "uvicorn[standard]>=0.22.0,<1.0" \
    gunicorn \
    python-multipart \
    orjson

# 6. Core-ML-Abhängigkeiten installieren
RUN pip3 install --no-cache-dir \
    numpy>=1.21.0 \
    scipy \
    scikit-learn \
    tqdm \
    sentencepiece \
    huggingface-hub

# 7. Sentence-Transformers (nur Python-Code, vorhandene Dependencies)
RUN pip3 install --no-cache-dir sentence-transformers --no-deps

# 8. Weitere ML-Bibliotheken installieren
RUN pip3 install --no-cache-dir \
    pillow \
    transformers \
    torch \
    torchvision \
    torchaudio

# 9. Arbeitsverzeichnis setzen
WORKDIR /usr/src

#  ONNX Runtime installieren
#  Für CPU-Ausführung:
RUN pip3 install --no-cache-dir \
    --index-url https://pypi.org/simple \
    onnxruntime

# ONNX Runtime GPU für Python 3.10 / ARM64 installieren
RUN wget -qO onnxruntime_gpu-1.20.0-cp310-cp310-linux_aarch64.whl \
       https://github.com/ultralytics/assets/releases/download/v0.0.0/onnxruntime_gpu-1.20.0-cp310-cp310-linux_aarch64.whl && \
    pip3 install --no-cache-dir onnxruntime_gpu-1.20.0-cp310-cp310-linux_aarch64.whl && \
    rm onnxruntime_gpu-1.20.0-cp310-cp310-linux_aarch64.whl

# System-Paket für OpenCV-Python installieren
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-opencv && \
    rm -rf /var/lib/apt/lists/*

# OpenCV-Python installieren (ARM64 wheel von PyPI)
RUN pip3 install --no-cache-dir \
    --index-url https://pypi.org/simple \
    opencv-python


# 10. Immich ML-Code aus offiziellem Release-Image kopieren
COPY --from=ghcr.io/immich-app/immich-machine-learning:release /usr/src ./

# 11. Umgebungsvariablen
ENV PYTHONPATH=/usr/src \
    TRANSFORMERS_CACHE=/cache \
    TORCH_HOME=/cache \
    DEVICE=cuda

# 12. Dienst-Port freigeben
EXPOSE 3003

# 13. Startkommando
CMD ["python3", "-m", "immich_ml"]
