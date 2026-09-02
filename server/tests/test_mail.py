import ssl
from email.message import EmailMessage

import pytest

from pluris_server.config import Settings
from pluris_server.mail import SmtpEmailSender


def test_smtp_starttls_uses_a_verifying_context(monkeypatch: pytest.MonkeyPatch) -> None:
    contexts: list[ssl.SSLContext] = []
    messages: list[EmailMessage] = []

    class CapturingSmtp:
        def __init__(self, *_args: object, **_kwargs: object) -> None:
            pass

        def __enter__(self) -> "CapturingSmtp":
            return self

        def __exit__(self, *_args: object) -> None:
            pass

        def starttls(self, *, context: ssl.SSLContext) -> None:
            contexts.append(context)

        def send_message(self, message: EmailMessage) -> None:
            messages.append(message)

    monkeypatch.setattr("pluris_server.mail.smtplib.SMTP", CapturingSmtp)
    sender = SmtpEmailSender(
        Settings(
            smtp_host="smtp.example.test",
            smtp_from_email="pluris@example.test",
        )
    )

    sender._send("person@example.test", "reset-token")

    assert len(contexts) == 1
    assert contexts[0].check_hostname
    assert contexts[0].verify_mode is ssl.CERT_REQUIRED
    assert "reset-token" in messages[0].get_content()
    assert "I have a reset token" in messages[0].get_content()
