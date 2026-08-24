import asyncio
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager, suppress
from pathlib import Path
from urllib.parse import urlsplit

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.engine import make_url
from starlette.middleware.trustedhost import TrustedHostMiddleware

from pluris_server import __version__
from pluris_server.account_cleanup import sweep_deleted_accounts
from pluris_server.backup_cleanup import sweep_backup_deletions, sweep_incomplete_backup_snapshots
from pluris_server.backup_storage import FilesystemBackupObjectStore
from pluris_server.config import Settings, get_settings
from pluris_server.database import Base, create_engine, create_session_factory
from pluris_server.http_security import RequestBodyLimitMiddleware, SecurityHeadersMiddleware
from pluris_server.mail import create_email_sender
from pluris_server.rate_limit import DatabaseRateLimiter
from pluris_server.routers import auth, backups, friends, health, server_info


def create_app(settings: Settings | None = None) -> FastAPI:
    active_settings = settings or get_settings()
    active_settings.validate_for_startup()
    if active_settings.database_url.startswith("sqlite"):
        database_path = make_url(active_settings.database_url).database
        if database_path not in {None, ":memory:", ""}:
            Path(database_path).expanduser().parent.mkdir(parents=True, exist_ok=True)
    engine = create_engine(active_settings.database_url)

    @asynccontextmanager
    async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
        if active_settings.environment != "production":
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)
        async with _app.state.session_factory() as cleanup_session:
            await sweep_backup_deletions(
                cleanup_session,
                _app.state.backup_object_store,
            )
            await sweep_incomplete_backup_snapshots(
                cleanup_session,
                _app.state.backup_object_store,
                ttl_seconds=active_settings.backup_incomplete_snapshot_ttl_seconds,
            )
            await sweep_deleted_accounts(cleanup_session, _app.state.backup_object_store)

        async def run_account_cleanup() -> None:
            while True:
                await asyncio.sleep(active_settings.account_cleanup_interval_seconds)
                async with _app.state.session_factory() as cleanup_session:
                    await sweep_deleted_accounts(
                        cleanup_session,
                        _app.state.backup_object_store,
                    )
                    await sweep_incomplete_backup_snapshots(
                        cleanup_session,
                        _app.state.backup_object_store,
                        ttl_seconds=active_settings.backup_incomplete_snapshot_ttl_seconds,
                    )

        cleanup_task = asyncio.create_task(run_account_cleanup())
        try:
            yield
        finally:
            cleanup_task.cancel()
            with suppress(asyncio.CancelledError):
                await cleanup_task
            await engine.dispose()

    app = FastAPI(
        title="Pluris Haven Friends",
        description="Optional account, backup, friend, and sharing service",
        version=__version__,
        docs_url="/docs" if active_settings.environment != "production" else None,
        redoc_url=None,
        lifespan=lifespan,
    )
    app.state.settings = active_settings
    app.state.email_sender = create_email_sender(active_settings)
    app.state.engine = engine
    app.state.session_factory = create_session_factory(engine)
    app.state.auth_rate_limiter = DatabaseRateLimiter(
        app.state.session_factory,
        max_attempts=active_settings.auth_rate_limit_attempts,
        window_seconds=active_settings.auth_rate_limit_window_seconds,
        key_pepper=active_settings.friend_code_pepper,
    )
    app.state.refresh_ip_rate_limiter = DatabaseRateLimiter(
        app.state.session_factory,
        max_attempts=active_settings.refresh_ip_rate_limit_attempts,
        window_seconds=active_settings.auth_rate_limit_window_seconds,
        key_pepper=active_settings.friend_code_pepper,
    )
    app.state.friend_request_rate_limiter = DatabaseRateLimiter(
        app.state.session_factory,
        max_attempts=active_settings.friend_request_rate_limit_attempts,
        window_seconds=active_settings.friend_request_rate_limit_window_seconds,
        key_pepper=active_settings.friend_code_pepper,
    )
    app.state.backup_object_store = FilesystemBackupObjectStore(
        Path(active_settings.backup_object_dir),
        max_chunk_bytes=active_settings.backup_max_chunk_bytes,
    )

    public_host = urlsplit(active_settings.public_url).hostname
    trusted_hosts = set(active_settings.trusted_hosts)
    if public_host:
        trusted_hosts.add(public_host)
    if active_settings.environment != "production":
        trusted_hosts.update({"localhost", "127.0.0.1", "testserver"})
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=sorted(trusted_hosts),
    )
    app.add_middleware(
        RequestBodyLimitMiddleware,
        maximum_bytes=active_settings.auth_max_body_bytes,
    )
    app.add_middleware(
        SecurityHeadersMiddleware,
        enable_hsts=active_settings.public_url.startswith("https://"),
    )

    if active_settings.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=list(active_settings.cors_origins),
            allow_credentials=False,
            allow_methods=["GET", "POST", "PUT", "DELETE"],
            allow_headers=["Authorization", "Content-Type", "X-Content-SHA256"],
            expose_headers=["X-Content-SHA256"],
        )

    app.include_router(health.router)
    app.include_router(server_info.router)
    app.include_router(auth.router)
    app.include_router(backups.router)
    app.include_router(friends.router)
    return app


app = create_app()
