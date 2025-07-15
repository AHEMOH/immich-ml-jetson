# ----------------------------------------
# Dockerfile für Immich ML auf Jetson Xavier
# Basis: dustynv/nano_llm:r35.4.1 (JetPack 5.1 mit CUDA 11.4)
# ----------------------------------------

# 1. Optimierte Basis mit vorinstallierten Jetson-Optimierungen
FROM dustynv/nano_llm:r35.4.1

# System-Tools installieren und Python 3.10 hinzufügen
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      software-properties-common \
      python3.10 \
      python3.10-venv \
      python3.10-distutils \
      python3.10-dev \
      curl && \
    rm -rf /var/lib/apt/lists/*

# `python3` und `pip3` auf Version 3.10 umschalten
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3

# Bestätigen, dass die neue Version aktiv ist
RUN python3 --version && pip3 --version

# 2. System-Pakete installieren (Protobuf, pip, setuptools)
#    - protobuf-compiler für UFF/ONNX-Konvertierung
#    - Python-Build-Tools für spätere pip-Installationen
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3-pip \
      python3-setuptools \
      protobuf-compiler \
      libprotobuf-dev && \
    rm -rf /var/lib/apt/lists/*

# 3. Pip, setuptools und wheel auf neueste Version heben
RUN pip3 install --upgrade pip setuptools wheel \
    --index-url https://pypi.org/simple \
    --no-cache-dir

# 4. Aiocache direkt aus Git installieren (ohne Build-Isolation)
RUN pip3 install --no-build-isolation --no-cache-dir \
    "git+https://github.com/aio-libs/aiocache.git@v0.12.3#egg=aiocache"

# 5. Wichtige Framework-Pakete von PyPI installieren
#    - pydantic-settings: Settings-Management Pydantic v2
#    - rich: verbesserte Konsolenausgabe
#    - FastAPI & Uvicorn & Gunicorn für Web-Server
#    - python-multipart & orjson für Uploads & JSON-Performance
RUN pip3 install --no-cache-dir \
    --index-url https://pypi.org/simple \
    "pydantic-settings>=2.5.2,<3" \
    rich \
    fastapi \
    "uvicorn[standard]>=0.22.0,<1.0" \
    gunicorn \
    python-multipart \
    orjson

# 6. OpenCV als System-Paket (ARM64-kompatibel)
#    - python3-opencv liefert cv2 für Jetson
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-opencv && \
    rm -rf /var/lib/apt/lists/*

# 7. Core-ML-Abhängigkeiten installieren
#    - NumPy, SciPy, scikit-learn, tqdm, sentencepiece, huggingface-hub
RUN pip3 install --no-cache-dir \
    --index-url https://pypi.org/simple \
    numpy>=1.21.0 \
    scipy \
    scikit-learn \
    tqdm \
    sentencepiece \
    huggingface-hub

# 8. Sentence-Transformers (nur Python-Code, keine Neuauflösung der Dependencies)
RUN pip3 install --no-cache-dir \
    --index-url https://pypi.org/simple \
    sentence-transformers --no-deps

# 9. Weitere ML-Bibliotheken installieren
#    - Transformers, Torch (inkl. torchvision, torchaudio)
RUN pip3 install --no-cache-dir \
    --index-url https://pypi.org/simple \
    pillow \
    transformers \
    torch \
    torchvision \
    torchaudio

# 10. Arbeitsverzeichnis für Immich-ML setzen
WORKDIR /usr/src

# 11. Immich ML-Code aus dem offiziellen Release-Image kopieren
COPY --from=ghcr.io/immich-app/immich-machine-learning:release /usr/src ./

# 12. Umgebungsvariablen
ENV PYTHONPATH=/usr/src \
    TRANSFORMERS_CACHE=/cache \
    TORCH_HOME=/cache \
    DEVICE=cuda

# 13. Port freigeben (Standard ML-Service-Port)
EXPOSE 3003

# 14. Startbefehl
CMD ["python3", "-m", "immich_ml"]
