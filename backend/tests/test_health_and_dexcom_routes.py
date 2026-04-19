from urllib.parse import parse_qs, urlparse

from fastapi.testclient import TestClient

from app.main import app
from app.services.container import get_dexcom_service, get_dexcom_store


def _extract_state(auth_url: str) -> str:
    parsed = urlparse(auth_url)
    query = parse_qs(parsed.query)
    return query["state"][0]


def test_health_endpoints(client: TestClient) -> None:
    health = client.get("/healthz")
    assert health.status_code == 200
    assert health.json() == {"status": "ok"}

    ready = client.get("/readyz")
    assert ready.status_code == 200
    assert ready.json()["status"] == "ready"
    assert ready.json()["env"] == "local"


def test_start_status_callback_success_sync_disconnect_flow(client: TestClient) -> None:
    user = "user-flow"

    start = client.post("/dexcom/connect/start", headers={"X-User-Id": user})
    assert start.status_code == 200
    start_payload = start.json()
    assert start_payload["connection_status"] == "pending"
    assert "api.dexcom.com" in start_payload["authorization_url"]

    status_pending = client.get("/dexcom/connect/status", headers={"X-User-Id": user})
    assert status_pending.status_code == 200
    assert status_pending.json()["status"] == "pending"

    state = _extract_state(start_payload["authorization_url"])
    callback = client.get(
        f"/dexcom/connect/callback?state={state}&code=fake-auth-code",
        follow_redirects=False,
    )
    assert callback.status_code == 302
    assert callback.headers["location"].startswith("foodie://dexcom-connected?status=connected")

    status_connected = client.get("/dexcom/connect/status", headers={"X-User-Id": user})
    assert status_connected.status_code == 200
    assert status_connected.json()["status"] == "connected"
    assert status_connected.json()["connected_at"] is not None
    assert status_connected.json()["last_sync_at"] is None

    sync = client.post("/dexcom/sync", headers={"X-User-Id": user})
    assert sync.status_code == 200
    assert sync.json()["status"] == "completed"

    status_after_sync = client.get("/dexcom/connect/status", headers={"X-User-Id": user})
    assert status_after_sync.status_code == 200
    assert status_after_sync.json()["last_sync_at"] is not None

    disconnect = client.post("/dexcom/disconnect", headers={"X-User-Id": user})
    assert disconnect.status_code == 200
    assert disconnect.json()["status"] == "disconnected"

    status_after_disconnect = client.get("/dexcom/connect/status", headers={"X-User-Id": user})
    assert status_after_disconnect.status_code == 200
    assert status_after_disconnect.json()["status"] == "disconnected"


def test_callback_error_marks_connection_error_and_redirects(client: TestClient) -> None:
    user = "user-error"
    start = client.post("/dexcom/connect/start", headers={"X-User-Id": user})
    state = _extract_state(start.json()["authorization_url"])

    callback = client.get(
        f"/dexcom/connect/callback?state={state}&error=access_denied",
        follow_redirects=False,
    )
    assert callback.status_code == 302
    assert callback.headers["location"].startswith("foodie://dexcom-connected?status=error")

    status = client.get("/dexcom/connect/status", headers={"X-User-Id": user})
    assert status.status_code == 200
    assert status.json()["status"] == "error"
    assert "authorization failed" in status.json()["error_message"].lower()


def test_callback_invalid_state_returns_error_envelope(client: TestClient) -> None:
    response = client.get("/dexcom/connect/callback?state=bad-state&code=abc")
    assert response.status_code == 400
    payload = response.json()
    assert payload["error"]["code"] == "dexcom_invalid_state"


def test_sync_requires_connected_state(client: TestClient) -> None:
    response = client.post("/dexcom/sync", headers={"X-User-Id": "user-not-connected"})
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "dexcom_not_connected"


def test_users_are_isolated(client: TestClient) -> None:
    client.post("/dexcom/connect/start", headers={"X-User-Id": "user-a"})

    status_b = client.get("/dexcom/connect/status", headers={"X-User-Id": "user-b"})
    assert status_b.status_code == 200
    assert status_b.json()["status"] == "disconnected"


def test_connection_persists_across_service_cache_reset(client: TestClient) -> None:
    user = "persisted-user"
    start = client.post("/dexcom/connect/start", headers={"X-User-Id": user})
    state = _extract_state(start.json()["authorization_url"])

    callback = client.get(
        f"/dexcom/connect/callback?state={state}&code=fake-auth-code",
        follow_redirects=False,
    )
    assert callback.status_code == 302

    get_dexcom_store.cache_clear()
    get_dexcom_service.cache_clear()

    persisted = client.get("/dexcom/connect/status", headers={"X-User-Id": user})
    assert persisted.status_code == 200
    assert persisted.json()["status"] == "connected"


def test_weekly_summary_and_readings_routes_return_persisted_glucose(client: TestClient) -> None:
    user = "user-cgm-summary"
    start = client.post("/dexcom/connect/start", headers={"X-User-Id": user})
    state = _extract_state(start.json()["authorization_url"])

    callback = client.get(
        f"/dexcom/connect/callback?state={state}&code=fake-auth-code",
        follow_redirects=False,
    )
    assert callback.status_code == 302

    sync = client.post("/dexcom/sync", headers={"X-User-Id": user})
    assert sync.status_code == 200

    summary = client.get("/cgm/summary/weekly", headers={"X-User-Id": user})
    assert summary.status_code == 200
    summary_payload = summary.json()["summary"]
    assert summary_payload["targetLowMgdl"] == 70
    assert summary_payload["targetHighMgdl"] == 180
    assert summary_payload["averageMgdl"] is not None
    assert summary_payload["timeInRangePercent"] is not None
    assert len(summary_payload["readings"]) > 0

    readings = client.get("/cgm/readings", headers={"X-User-Id": user})
    assert readings.status_code == 200
    reading_payload = readings.json()["readings"]
    assert len(reading_payload) > 0
    assert {"id", "timestamp", "valueMgdl", "source", "trend"} <= set(reading_payload[0].keys())
