FROM python:3.14-slim@sha256:35caba83af2fe6da9a5d922f9b0156f21d1246a48278c58a08bd253303ba42e8 AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN groupadd --system pluris && useradd --system --gid pluris --home /app pluris
WORKDIR /app
RUN install -d -o pluris -g pluris /app/data /app/data/backups

COPY pyproject.toml uv.lock README.md alembic.ini ./
RUN pip install uv==0.13.5 \
    && uv export --frozen --no-dev --no-hashes --no-emit-project --output-file /tmp/requirements.txt \
    && uv pip install --system --requirement /tmp/requirements.txt \
    && pip uninstall --yes uv \
    && rm /tmp/requirements.txt

COPY alembic ./alembic
COPY pluris_server ./pluris_server
RUN pip install --no-deps .

USER pluris
EXPOSE 8000
CMD ["sh", "-c", "exec uvicorn pluris_server.main:app --host 0.0.0.0 --port 8000 --proxy-headers --forwarded-allow-ips=\"${PLURIS_FORWARDED_ALLOW_IPS:-127.0.0.1,::1}\""]
