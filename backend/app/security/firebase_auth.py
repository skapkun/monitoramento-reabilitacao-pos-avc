from __future__ import annotations

from dataclasses import dataclass
from typing import Annotated, Any, Optional

import firebase_admin
from fastapi import Header, HTTPException, status
from firebase_admin import auth
from google.auth.exceptions import DefaultCredentialsError
from google.auth.transport.requests import Request
from google.oauth2 import id_token

from app.config import settings


@dataclass(frozen=True)
class AuthenticatedUser:
    uid: str
    email: Optional[str] = None


def _ensure_firebase_app() -> None:
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app(options={"projectId": settings.firebase_project_id})


def _unauthorized(message: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=message,
        headers={"WWW-Authenticate": "Bearer"},
    )


def verify_firebase_token(token: str) -> dict[str, Any]:
    if settings.firebase_check_revoked:
        _ensure_firebase_app()
        return auth.verify_id_token(token, check_revoked=True)

    claims = id_token.verify_token(
        token,
        request=Request(),
        audience=settings.firebase_project_id,
        certs_url=(
            "https://www.googleapis.com/robot/v1/metadata/x509/"
            "securetoken@system.gserviceaccount.com"
        ),
    )
    expected_issuer = f"https://securetoken.google.com/{settings.firebase_project_id}"
    subject = claims.get("sub")
    if claims.get("iss") != expected_issuer:
        raise ValueError("invalid issuer")
    if not isinstance(subject, str) or not subject or len(subject) > 128:
        raise ValueError("invalid subject")
    claims["uid"] = subject
    return claims


def require_authenticated_user(
    authorization: Annotated[Optional[str], Header()] = None,
) -> AuthenticatedUser:
    if settings.auth_mode == "disabled":
        return AuthenticatedUser(uid="local-development")
    if settings.auth_mode != "firebase":
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="O modo de autenticação da API é inválido.",
        )
    if not authorization or not authorization.startswith("Bearer "):
        raise _unauthorized("Informe um token de acesso válido.")
    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise _unauthorized("Informe um token de acesso válido.")
    try:
        claims = verify_firebase_token(token)
    except DefaultCredentialsError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="A autenticação do servidor não está configurada.",
        ) from error
    except Exception as error:
        raise _unauthorized("Token de acesso inválido ou expirado.") from error
    uid = claims.get("uid") or claims.get("sub")
    if not isinstance(uid, str) or not uid:
        raise _unauthorized("Token de acesso inválido ou expirado.")
    email = claims.get("email")
    return AuthenticatedUser(
        uid=uid,
        email=email if isinstance(email, str) else None,
    )
