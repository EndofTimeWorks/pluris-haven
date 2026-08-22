import json
import logging
from enum import StrEnum


class SecuritySignal(StrEnum):
    AUTH_REJECTED = "security.auth.rejected"
    AUTH_RATE_LIMITED = "security.auth.rate_limited"
    CAPACITY_REJECTED = "security.capacity.rejected"
    READINESS_FAILED = "security.readiness.failed"


class SecurityOperation(StrEnum):
    REGISTER = "register"
    LOGIN = "login"
    REFRESH = "refresh"
    CHANGE_PASSWORD = "change_password"
    PASSWORD_RESET_REQUEST = "password_reset_request"
    PASSWORD_RESET = "password_reset"
    DELETE_ACCOUNT = "delete_account"
    BACKUP_SNAPSHOT = "backup_snapshot"
    BACKUP_CHUNK = "backup_chunk"
    DATABASE = "database"


class SecurityReason(StrEnum):
    INVALID_CREDENTIALS = "invalid_credentials"
    DISABLED_ACCOUNT = "disabled_account"
    REGISTRATION_DISABLED = "registration_disabled"
    ACCOUNT_CONFLICT = "account_conflict"
    WRONG_CURRENT_PASSWORD = "wrong_current_password"
    RATE_LIMIT = "rate_limit"
    SNAPSHOT_LIMIT = "snapshot_limit"
    STORAGE_QUOTA = "storage_quota"
    PAYLOAD_TOO_LARGE = "payload_too_large"
    DATABASE_UNAVAILABLE = "database_unavailable"


_logger = logging.getLogger("pluris.security")


def log_security_signal(
    signal: SecuritySignal,
    *,
    operation: SecurityOperation,
    reason: SecurityReason,
) -> None:
    """Log a stable security signal without identity or request data."""

    _logger.warning(
        json.dumps(
            {
                "event": signal.value,
                "operation": operation.value,
                "reason": reason.value,
            },
            separators=(",", ":"),
            sort_keys=True,
        )
    )
