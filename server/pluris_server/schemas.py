from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=1024)
    display_name: str = Field(min_length=1, max_length=80)
    device_name: str = Field(default="Unknown device", min_length=1, max_length=120)

    @field_validator("display_name", "device_name")
    @classmethod
    def strip_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("must not be blank")
        return value


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=1024)
    device_name: str = Field(default="Unknown device", min_length=1, max_length=120)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=32, max_length=512)
    rotation_nonce: str | None = Field(
        default=None,
        min_length=16,
        max_length=128,
        pattern=r"^[A-Za-z0-9_-]+$",
    )


class DeleteAccountRequest(BaseModel):
    password: str = Field(min_length=1, max_length=1024)


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1, max_length=1024)
    new_password: str = Field(min_length=12, max_length=1024)


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RegistrationResponse(TokenPair):
    friend_code: str


class UserView(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: EmailStr
    display_name: str
    created_at: datetime


class PublicUserView(BaseModel):
    id: str
    display_name: str


class SessionView(BaseModel):
    id: str
    device_name: str
    created_at: datetime
    last_used_at: datetime
    expires_at: datetime
    current: bool


class SecurityEventView(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    occurred_at: datetime


class FriendCodeResponse(BaseModel):
    friend_code: str


class FriendRequestCreate(BaseModel):
    friend_code: str = Field(min_length=8, max_length=40)


class FriendRequestView(BaseModel):
    id: str
    direction: str
    status: str
    user: PublicUserView
    created_at: datetime
    updated_at: datetime


class FriendView(BaseModel):
    friendship_id: str
    user: PublicUserView
    created_at: datetime


class BlockCreate(BaseModel):
    user_id: str


class BlockView(BaseModel):
    user: PublicUserView
    created_at: datetime


class MessageResponse(BaseModel):
    detail: str


class BackupSnapshotCreate(BaseModel):
    snapshot_id: str = Field(pattern=r"^[A-Za-z0-9_-]{1,128}$")
    manifest_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    chunk_count: int = Field(ge=1, le=100_000)
    total_bytes: int = Field(ge=1, le=1_000_000_000_000)
    created_at: datetime | None = None


class BackupSnapshotView(BaseModel):
    snapshot_id: str
    manifest_sha256: str
    chunk_count: int
    uploaded_chunks: int
    total_bytes: int
    uploaded_bytes: int
    created_at: datetime


class BackupChunkView(BaseModel):
    snapshot_id: str
    index: int
    sha256: str
    size: int


class ServerInfo(BaseModel):
    protocol_version: int = 1
    server_id: str
    name: str
    mode: str
    operator: str
    public_url: str
    privacy_policy_url: str
    terms_url: str
    support_email: str
    software_version: str
    minimum_age: int = 13
    registration_enabled: bool
    friends_enabled: bool
    capabilities: list[str]
    federation_enabled: bool = False
    encrypted_sync_enabled: bool = False
