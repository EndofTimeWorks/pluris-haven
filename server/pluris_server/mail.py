import asyncio
import smtplib
import ssl
from dataclasses import dataclass
from email.message import EmailMessage
from typing import Protocol

from pluris_server.config import Settings


class EmailSender(Protocol):
    async def send_password_reset(self, recipient: str, token: str) -> None: ...


@dataclass(frozen=True)
class SentPasswordReset:
    recipient: str
    token: str


class MemoryEmailSender:
    def __init__(self) -> None:
        self.sent: list[SentPasswordReset] = []

    async def send_password_reset(self, recipient: str, token: str) -> None:
        self.sent.append(SentPasswordReset(recipient=recipient, token=token))


class SmtpEmailSender:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def send_password_reset(self, recipient: str, token: str) -> None:
        await asyncio.to_thread(self._send, recipient, token)

    def _send(self, recipient: str, token: str) -> None:
        settings = self._settings
        message = EmailMessage()
        message["From"] = settings.smtp_from_email
        message["To"] = recipient
        message["Subject"] = "Reset your Pluris Haven password"
        message.set_content(
            "In Pluris Haven, choose ‘Forgot password?’ and then ‘I have a reset token’. "
            f"Enter this reset token within {settings.password_reset_token_minutes} minutes:\n\n{token}\n"
        )
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as smtp:
            smtp.starttls(context=ssl.create_default_context())
            if settings.smtp_username:
                smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(message)


def create_email_sender(settings: Settings) -> EmailSender:
    if settings.smtp_host and settings.smtp_from_email:
        return SmtpEmailSender(settings)
    return MemoryEmailSender()
