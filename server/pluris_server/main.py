from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.engine import make_url

from pluris_server import __version__
from pluris_server.backup_cleanup import sweep_backup_deletions
from pluris_server.backup_storage import FilesystemBackupObjectStore
from pluris_server.config import Settings, get_settings
from pluris_server.database import Base, create_engine, create_session_factory
from pluris_server.rate_limit import InMemoryRateLimiter
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
        yield
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
    app.state.engine = engine
    app.state.session_factory = create_session_factory(engine)
    app.state.auth_rate_limiter = InMemoryRateLimiter(
        max_attempts=active_settings.auth_rate_limit_attempts,
        window_seconds=active_settings.auth_rate_limit_window_seconds,
    )
    app.state.friend_request_rate_limiter = InMemoryRateLimiter(
        max_attempts=active_settings.friend_request_rate_limit_attempts,
        window_seconds=active_settings.friend_request_rate_limit_window_seconds,
    )
    app.state.backup_object_store = FilesystemBackupObjectStore(
        Path(active_settings.backup_object_dir),
        max_chunk_bytes=active_settings.backup_max_chunk_bytes,
    )

    if active_settings.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=list(active_settings.cors_origins),
            allow_credentials=False,
            allow_methods=["GET", "POST", "PUT", "DELETE"],
            allow_headers=["Authorization", "Content-Type"],
        )

    app.include_router(health.router)
    app.include_router(server_info.router)
    app.include_router(auth.router)
    app.include_router(backups.router)
    app.include_router(friends.router)
    return app


app = create_app()
