from pluris_server.security import digest_token


def test_secret_digests_are_domain_separated() -> None:
    token = "same-secret-material"

    assert digest_token(token, purpose="refresh") != digest_token(
        token, purpose="rotation_nonce"
    )
    assert digest_token(token, purpose="refresh") != digest_token(
        token, purpose="password_reset"
    )
