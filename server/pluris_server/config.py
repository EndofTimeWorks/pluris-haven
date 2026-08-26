from functools import lru_cache
from typing import Annotated, Literal
from urllib.parse import urlsplit
from uuid import UUID

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="PLURIS_",
        extra="ignore",
    )

    environment: Literal["development", "test", "production"] = "development"
    database_url: str = "sqlite+aiosqlite:///./data/pluris-server.db"
    jwt_secret: str = "development-only-change-me"
    friend_code_pepper: str = "development-only-change-me"
    access_token_minutes: int = 15
    refresh_token_days: int = 30
    registration_enabled: bool = False
    friends_enabled: bool = False
    server_id: UUID = UUID(int=0)
    server_name: str = "Private Pluris Haven server"
    server_mode: Literal["official", "community", "private"] = "private"
    server_operator: str = "Unconfigured operator"
    public_url: str = "http://localhost:8000"
    privacy_policy_url: str = ""
    terms_url: str = ""
    support_email: str = ""
    smtp_host: str = ""
    smtp_port: int = Field(default=587, ge=1, le=65_535)
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from_email: str = ""
    password_reset_token_minutes: int = Field(default=60, ge=5, le=1_440)
    backup_object_dir: str = "./data/backups"
    backup_max_chunk_bytes: int = 8 * 1024 * 1024
    backup_max_snapshots_per_user: int = Field(default=10, ge=1, le=10_000)
    backup_max_total_bytes_per_user: int = Field(
        default=1 * 1024 * 1024 * 1024,
        ge=1 * 1024 * 1024,
        le=1 * 1024 * 1024 * 1024 * 1024,
    )
    backup_incomplete_snapshot_ttl_seconds: int = Field(default=86_400, ge=3_600, le=2_592_000)
    friend_request_cooldown_seconds: int = Field(default=86_400, ge=0, le=2_592_000)
    friend_request_rate_limit_attempts: int = Field(default=10, ge=1, le=1_000)
    friend_request_rate_limit_window_seconds: int = Field(default=60, ge=1, le=86_400)
    max_blocks_per_user: int = Field(default=1_000, ge=1, le=100_000)
    auth_rate_limit_attempts: int = Field(default=10, ge=1, le=1_000)
    auth_rate_limit_window_seconds: int = Field(default=60, ge=1, le=86_400)
    refresh_ip_rate_limit_attempts: int = Field(default=120, ge=1, le=10_000)
    refresh_retry_grace_seconds: int = Field(default=10, ge=0, le=60)
    auth_max_body_bytes: int = Field(default=64 * 1024, ge=1024, le=1024 * 1024)
    account_cleanup_interval_seconds: int = Field(default=3600, ge=60, le=86_400)
    cors_origins: Annotated[tuple[str, ...], NoDecode] = ()
    trusted_hosts: Annotated[tuple[str, ...], NoDecode] = ()

    @field_validator("cors_origins", "trusted_hosts", mode="before")
    @classmethod
    def parse_origins(cls, value: object) -> object:
        if isinstance(value, str):
            return tuple(part.strip() for part in value.split(",") if part.strip())
        return value

    def validate_for_startup(self) -> None:
        weak_values = {"", "development-only-change-me", "changeme"}
        if self.jwt_secret in weak_values or self.jwt_secret.startswith("replace-"):
            raise RuntimeError("PLURIS_JWT_SECRET must be set")
        if len(self.jwt_secret) < 32:
            raise RuntimeError("PLURIS_JWT_SECRET must contain at least 32 characters")
        if self.friend_code_pepper in weak_values or self.friend_code_pepper.startswith("replace-"):
            raise RuntimeError("PLURIS_FRIEND_CODE_PEPPER must be set")
        if len(self.friend_code_pepper) < 32:
            raise RuntimeError("PLURIS_FRIEND_CODE_PEPPER must contain at least 32 characters")
        if self.environment != "production":
            return
        if not self.database_url.startswith(("postgresql://", "postgresql+")):
            raise RuntimeError("Production requires PostgreSQL")
        public_url = urlsplit(self.public_url)
        if (
            public_url.scheme != "https"
            or public_url.hostname is None
            or public_url.username is not None
            or public_url.password is not None
        ):
            raise RuntimeError("PLURIS_PUBLIC_URL must be an HTTPS URL in production")
        if self.registration_enabled:
            raise RuntimeError(
                "Production registration requires verified email, which is not implemented yet"
            )
        if self.server_id.int == 0:
            raise RuntimeError("PLURIS_SERVER_ID must be a stable, non-zero UUID")
        if self.registration_enabled or self.friends_enabled:
            required_metadata = {
                "PLURIS_PRIVACY_POLICY_URL": self.privacy_policy_url,
                "PLURIS_TERMS_URL": self.terms_url,
                "PLURIS_SUPPORT_EMAIL": self.support_email,
            }
            missing = [name for name, value in required_metadata.items() if not value.strip()]
            if missing:
                raise RuntimeError(f"Public account features require: {', '.join(missing)}")


@lru_cache
def get_settings() -> Settings:
    return Settings()
