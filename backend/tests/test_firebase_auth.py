from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from google.auth.exceptions import DefaultCredentialsError

from app.security import firebase_auth


def test_disabled_auth_mode_returns_local_user(monkeypatch) -> None:
    monkeypatch.setattr(
        firebase_auth,
        "settings",
        SimpleNamespace(auth_mode="disabled"),
    )

    user = firebase_auth.require_authenticated_user(None)

    assert user.uid == "local-development"


def test_firebase_auth_mode_accepts_valid_bearer_token(monkeypatch) -> None:
    monkeypatch.setattr(
        firebase_auth,
        "settings",
        SimpleNamespace(auth_mode="firebase"),
    )
    monkeypatch.setattr(
        firebase_auth,
        "verify_firebase_token",
        lambda token: {"uid": "user-123", "email": "pessoa@exemplo.com"},
    )

    user = firebase_auth.require_authenticated_user("Bearer valid-token")

    assert user.uid == "user-123"
    assert user.email == "pessoa@exemplo.com"


@pytest.mark.parametrize("authorization", [None, "", "Basic abc", "Bearer "])
def test_firebase_auth_mode_rejects_missing_token(monkeypatch, authorization) -> None:
    monkeypatch.setattr(
        firebase_auth,
        "settings",
        SimpleNamespace(auth_mode="firebase"),
    )

    with pytest.raises(HTTPException) as captured:
        firebase_auth.require_authenticated_user(authorization)

    assert captured.value.status_code == 401


def test_firebase_auth_mode_rejects_invalid_token(monkeypatch) -> None:
    monkeypatch.setattr(
        firebase_auth,
        "settings",
        SimpleNamespace(auth_mode="firebase"),
    )

    def reject(_token):
        raise ValueError("invalid signature")

    monkeypatch.setattr(firebase_auth, "verify_firebase_token", reject)

    with pytest.raises(HTTPException) as captured:
        firebase_auth.require_authenticated_user("Bearer invalid")

    assert captured.value.status_code == 401
    assert "signature" not in captured.value.detail


def test_firebase_auth_mode_reports_missing_server_credentials(monkeypatch) -> None:
    monkeypatch.setattr(
        firebase_auth,
        "settings",
        SimpleNamespace(auth_mode="firebase"),
    )

    def reject(_token):
        raise DefaultCredentialsError("missing credentials")

    monkeypatch.setattr(firebase_auth, "verify_firebase_token", reject)

    with pytest.raises(HTTPException) as captured:
        firebase_auth.require_authenticated_user("Bearer valid-looking-token")

    assert captured.value.status_code == 503
