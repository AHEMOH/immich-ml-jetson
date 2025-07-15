# Optimierte Base für JetPack 5.1 mit CUDA 11.4
FROM dustynv/nano_llm:r35.4.1

# 1. System-Dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3-setuptools \
      python3-pip \
      protobuf-compiler \
      libprotobuf-dev && \
    rm -rf /var/lib/apt/lists/*

# 2. Pip & Build-Tools aktualisieren
RUN pip3 install --upgrade pip setuptools wheel

# 3. Aiocache aus Git installieren
RUN pip3 install --no-build-isolation --no-cache-dir "git+https://github.com/aio-libs/aiocache.git@v0.12.3#egg=aiocache"

# 4. Weitere Python-Pakete installieren
RUN pip3 install --no-cache-dir \
    --index-url https://pypi.org/simple \
    "pydantic-settings>=2.5.2,<3" \
    rich \
    fastapi uvicorn[standard] gunicorn python-multipart orjson
    
# Jetson-spezifische Pakete (falls vom Jetson-Index benötigt)
# 1. Wheel aus Jetson-Index herunterladen und installieren
#RUN pip3 install --no-cache-dir \
#    https://jetson.webredirect.org/jp5/cu114/opencv_python-4.10.0-py3-none-any.whl
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-opencv && \
    rm -rf /var/lib/apt/lists/*


# 2. Die übrigen Pakete wie gewohnt installieren (über PyPI)
RUN pip3 install --no-cache-dir \
    pillow numpy transformers sentence-transformers \
    torch torchvision torchaudio

# Arbeitsverzeichnis setzen
WORKDIR /usr/src

# Zusätzliche Immich-spezifische Pakete installieren
RUN pip3 install --no-cache-dir "python-multipart>=0.0.6,<1.0"
RUN pip3 install --no-cache-dir "orjson>=3.9.5"

# Immich ML Code kopieren
COPY --from=ghcr.io/immich-app/immich-machine-learning:release /usr/src ./

# Umgebungsvariablen
ENV PYTHONPATH=/usr/src
ENV TRANSFORMERS_CACHE=/cache
ENV TORCH_HOME=/cache
ENV DEVICE=cuda

# Port freigeben
EXPOSE 3003

# Startbefehl
CMD ["python3", "-m", "immich_ml"]
