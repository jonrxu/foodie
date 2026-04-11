import os
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config.settings import get_settings
from app.main import app
from app.services.container import (
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

    get_settings.cache_clear()
    get_user_store.cache_clear()
    get_user_service.cache_clear()
    get_dexcom_client.cache_clear()
    get_dexcom_store.cache_clear()
    get_glucose_store.cache_clear()
    get_meal_store.cache_clear()
    get_cart_store.cache_clear()
    get_dexcom_service.cache_clear()
    get_cgm_service.cache_clear()
    get_meal_service.cache_clear()
    get_cart_service.cache_clear()

    yield

    get_settings.cache_clear()
    get_user_store.cache_clear()
    get_user_service.cache_clear()
    get_dexcom_client.cache_clear()
    get_dexcom_store.cache_clear()
    get_glucose_store.cache_clear()
    get_meal_store.cache_clear()
    get_cart_store.cache_clear()
    get_dexcom_service.cache_clear()
    get_cgm_service.cache_clear()
    get_meal_service.cache_clear()
    get_cart_service.cache_clear()
    os.environ.pop("BACKEND_DATABASE_PATH", None)
    os.environ.pop("DEXCOM_MOCK_OAUTH", None)


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)
