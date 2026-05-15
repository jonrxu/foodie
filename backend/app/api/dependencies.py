from dataclasses import dataclass

from fastapi import Depends, Header

from app.api.errors import AppError
from app.config.settings import Settings, get_settings
from app.services.auth_service import SupabaseAuthService
from app.services.container import get_auth_service


@dataclass
class RequestUser:
    id: str
    email: str | None = None
    is_authenticated: bool = False


async def get_current_user(
    authorization: str | None = Header(default=None),
    auth_service: SupabaseAuthService = Depends(get_auth_service),
) -> RequestUser:
    access_token = _extract_bearer_token(authorization)
    if not access_token:
        raise AppError(code="auth_required", message="Authentication required.", status_code=401)

    auth_user = auth_service.get_user(access_token)
    return RequestUser(id=auth_user.id, email=auth_user.email, is_authenticated=True)


async def get_current_user_id(current_user: RequestUser = Depends(get_current_user)) -> str:
    return current_user.id


def settings_dependency() -> Settings:
    return get_settings()


def _extract_bearer_token(authorization: str | None) -> str | None:
    if authorization is None:
        return None
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer":
        return None
    token = token.strip()
    return token or None
