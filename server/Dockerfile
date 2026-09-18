FROM python:3.14-slim@sha256:cad9a2c871761c413caa6fdd6441c783451e740a48aaeba60ae62a8b53525ef6 AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN groupadd --system pluris && useradd --system --gid pluris --home /app pluris
WORKDIR /app
RUN install -d -o pluris -g pluris /app/data /app/data/backups

COPY pyproject.toml uv.lock README.md alembic.ini ./
RUN pip install uv==0.11.28 \
    && uv export --frozen --no-dev --no-hashes --no-emit-project --output-file /tmp/requirements.txt \
    && uv pip install --system --requirement /tmp/requirements.txt \
    && pip uninstall --yes uv \
    && rm /tmp/requirements.txt

COPY alembic ./alembic
COPY pluris_server ./pluris_server
RUN pip install --no-deps .

USER pluris
EXPOSE 8000
CMD ["uvicorn", "pluris_server.main:app", "--host", "0.0.0.0", "--port", "8000"]
