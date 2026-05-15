from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx

from app.api.errors import AppError
from app.config.settings import Settings


@dataclass
class AuthenticatedUser:
    id: str
    email: str | None


class SupabaseAuthService:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    @property
    def is_configured(self) -> bool:
        return bool(self.settings.supabase_url and self.settings.supabase_publishable_key)

    def get_user(self, access_token: str) -> AuthenticatedUser:
        if not self.is_configured:
            raise AppError(
                code="auth_not_configured",
                message="Authentication provider is not configured.",
                status_code=500,
            )

        url = f"{self.settings.supabase_url.rstrip('/')}/auth/v1/user"
        try:
            response = httpx.get(
                url,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "apikey": self.settings.supabase_publishable_key,
                },
                timeout=10.0,
            )
        except httpx.HTTPError as exc:
            raise AppError(
                code="auth_provider_unreachable",
                message="Authentication provider could not be reached.",
                status_code=502,
            ) from exc

        if response.status_code == 401:
            raise AppError(
                code="auth_invalid_token",
                message="Authentication token is invalid or expired.",
                status_code=401,
            )

        if response.status_code >= 400:
            raise AppError(
                code="auth_provider_error",
                message="Authentication provider rejected the session.",
                status_code=502,
            )

        payload = response.json()
        user_id = str(payload.get("id") or "")
        if not user_id:
            raise AppError(
                code="auth_invalid_user",
                message="Authentication provider returned an invalid user payload.",
                status_code=502,
            )

        return AuthenticatedUser(
            id=user_id,
            email=self._string_or_none(payload.get("email")),
        )

    @staticmethod
    def _string_or_none(value: Any) -> str | None:
        if value is None:
            return None
        text = str(value).strip()
        return text or None
