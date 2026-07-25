FROM python:3.13-slim@sha256:bffeb7bd6a85767587059c6ba23e1e9122078e3aa3fa836099171b9bb5a9bb00 AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN groupadd --system pluris && useradd --system --gid pluris --home /app pluris
WORKDIR /app

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
