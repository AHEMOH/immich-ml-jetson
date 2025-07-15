# Optimierte Base für JetPack 5.1 mit CUDA 11.4
FROM dustynv/nano_llm:r35.4.1

# Arbeitsverzeichnis setzen
WORKDIR /usr/src

# Zusätzliche Immich-spezifische Pakete installieren
RUN pip3 install --no-cache-dir \
    aiocache>=0.12.1,<1.0 \
    python-multipart>=0.0.6,<1.0 \
    orjson>=3.9.5

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
