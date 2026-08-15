from fastapi import APIRouter

from pluris_server import __version__
from pluris_server.dependencies import AppSettings
from pluris_server.schemas import ServerInfo

router = APIRouter(tags=["server"])


def build_server_info(settings: AppSettings) -> ServerInfo:
    capabilities = [
        "accounts",
        "device_sessions",
        "friend_codes",
        "blocks",
        "encrypted_backup_chunks",
        "security_events_v1",
    ]
    if settings.friends_enabled:
        capabilities.append("friend_requests")
    return ServerInfo(
        server_id=str(settings.server_id),
        name=settings.server_name,
        mode=settings.server_mode,
        operator=settings.server_operator,
        public_url=settings.public_url,
        privacy_policy_url=settings.privacy_policy_url,
        terms_url=settings.terms_url,
        support_email=settings.support_email,
        software_version=__version__,
        registration_enabled=settings.registration_enabled,
        friends_enabled=settings.friends_enabled,
        capabilities=capabilities,
    )


@router.get("/.well-known/pluris-haven", response_model=ServerInfo)
async def well_known(settings: AppSettings) -> ServerInfo:
    return build_server_info(settings)


@router.get("/v1/server", response_model=ServerInfo)
async def server_info(settings: AppSettings) -> ServerInfo:
    return build_server_info(settings)
