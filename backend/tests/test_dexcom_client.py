from __future__ import annotations

from datetime import UTC, datetime

from app.clients.dexcom_client import DexcomApiClient
from app.config.settings import Settings


class _FakeResponse:
    def __init__(self, payload: dict) -> None:
        self._payload = payload

    def json(self) -> dict:
        return self._payload


def test_fetch_egvs_parses_production_records_payload(monkeypatch) -> None:
    client = DexcomApiClient(
        settings=Settings(
            dexcom_mock_oauth=False,
            dexcom_client_id="live-client",
            dexcom_client_secret="live-secret",
        )
    )

    def fake_get(*args, **kwargs) -> _FakeResponse:
        return _FakeResponse(
            {
                "recordType": "egv",
                "recordVersion": "3.0",
                "records": [
                    {
                        "recordId": "abc123",
                        "systemTime": "2026-05-16T15:49:01.964Z",
                        "value": 135,
                        "trend": "fortyFiveUp",
                    }
                ],
            }
        )

    monkeypatch.setattr(client, "_get", fake_get)

    readings = client.fetch_egvs(
        access_token="token",
        start=datetime(2026, 5, 9, tzinfo=UTC),
        end=datetime(2026, 5, 16, tzinfo=UTC),
    )

    assert len(readings) == 1
    assert readings[0].provider_record_id == "abc123"
    assert readings[0].value_mgdl == 135
    assert readings[0].trend == "fortyFiveUp"
    assert readings[0].timestamp == datetime(2026, 5, 16, 15, 49, 1, 964000, tzinfo=UTC)
