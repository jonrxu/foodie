import os
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.api.errors import AppError
from app.config.settings import get_settings
from app.main import app
from app.services.auth_service import AuthenticatedUser, SupabaseAuthService
from app.services.container import (
    get_agent_service,
    get_agent_store,
    get_cart_service,
    get_cart_store,
    get_cgm_service,
    get_dexcom_client,
    get_dexcom_service,
    get_dexcom_store,
    get_glucose_store,
    get_meal_service,
    get_meal_store,
    get_user_service,
    get_user_store,
)


@pytest.fixture(autouse=True)
def isolated_backend_state(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    database_path = tmp_path / "foodie_backend_test.sqlite3"
    monkeypatch.setenv("BACKEND_DATABASE_PATH", str(database_path))
    monkeypatch.setenv("DEXCOM_MOCK_OAUTH", "true")
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_PUBLISHABLE_KEY", "sb_publishable_test")

    def fake_get_user(self: SupabaseAuthService, access_token: str) -> AuthenticatedUser:
        prefix = "test-token:"
        if not access_token.startswith(prefix):
            raise AppError(
                code="auth_invalid_token",
                message="Authentication token is invalid or expired.",
                status_code=401,
            )

        payload = access_token.removeprefix(prefix)
        user_id, _, email = payload.partition("|")
        if not user_id:
            raise AppError(
                code="auth_invalid_user",
                message="Authentication provider returned an invalid user payload.",
                status_code=502,
            )
        resolved_email = email or f"{user_id}@example.com"
        return AuthenticatedUser(id=user_id, email=resolved_email)

    monkeypatch.setattr(SupabaseAuthService, "get_user", fake_get_user)

    get_settings.cache_clear()
    get_user_store.cache_clear()
    get_user_service.cache_clear()
    get_dexcom_client.cache_clear()
    get_dexcom_store.cache_clear()
    get_glucose_store.cache_clear()
    get_meal_store.cache_clear()
    get_cart_store.cache_clear()
    get_agent_store.cache_clear()
    get_dexcom_service.cache_clear()
    get_cgm_service.cache_clear()
    get_meal_service.cache_clear()
    get_cart_service.cache_clear()
    get_agent_service.cache_clear()

    yield

    get_settings.cache_clear()
    get_user_store.cache_clear()
    get_user_service.cache_clear()
    get_dexcom_client.cache_clear()
    get_dexcom_store.cache_clear()
    get_glucose_store.cache_clear()
    get_meal_store.cache_clear()
    get_cart_store.cache_clear()
    get_agent_store.cache_clear()
    get_dexcom_service.cache_clear()
    get_cgm_service.cache_clear()
    get_meal_service.cache_clear()
    get_cart_service.cache_clear()
    get_agent_service.cache_clear()
    os.environ.pop("BACKEND_DATABASE_PATH", None)
    os.environ.pop("DEXCOM_MOCK_OAUTH", None)
    os.environ.pop("SUPABASE_URL", None)
    os.environ.pop("SUPABASE_PUBLISHABLE_KEY", None)


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture
def auth_headers():
    def build(user_id: str, email: str | None = None) -> dict[str, str]:
        suffix = f"|{email}" if email else ""
        return {"Authorization": f"Bearer test-token:{user_id}{suffix}"}

    return build
