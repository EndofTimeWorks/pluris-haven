import asyncio
import smtplib
from dataclasses import dataclass
from email.message import EmailMessage
from typing import Protocol

from pluris_server.config import Settings


class EmailSender(Protocol):
    async def send_password_reset(self, recipient: str, link: str) -> None: ...


@dataclass(frozen=True)
class SentPasswordReset:
    recipient: str
    link: str


class MemoryEmailSender:
    def __init__(self) -> None:
        self.sent: list[SentPasswordReset] = []

    async def send_password_reset(self, recipient: str, link: str) -> None:
        self.sent.append(SentPasswordReset(recipient=recipient, link=link))


class SmtpEmailSender:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def send_password_reset(self, recipient: str, link: str) -> None:
        await asyncio.to_thread(self._send, recipient, link)

    def _send(self, recipient: str, link: str) -> None:
        settings = self._settings
        message = EmailMessage()
        message["From"] = settings.smtp_from_email
        message["To"] = recipient
        message["Subject"] = "Reset your Pluris Haven password"
        message.set_content(
            "Use this link to reset your Pluris Haven password. "
            f"It expires in {settings.password_reset_token_minutes} minutes:\n\n{link}\n"
        )
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as smtp:
            smtp.starttls()
            if settings.smtp_username:
                smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(message)


def create_email_sender(settings: Settings) -> EmailSender:
    if settings.smtp_host and settings.smtp_from_email:
        return SmtpEmailSender(settings)
    return MemoryEmailSender()
