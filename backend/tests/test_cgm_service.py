from __future__ import annotations

from dataclasses import replace
from datetime import UTC, datetime, timedelta

from app.clients.dexcom_client import DexcomDataRange, DexcomDataRangeWindow, DexcomEGVReading
from app.persistence.dexcom_store import DexcomConnectionRecord
from app.persistence.glucose_store import SQLiteGlucoseStore, StoredGlucoseReading
from app.services.cgm_service import CGMService


class _FakeDexcomStore:
    def __init__(self, record: DexcomConnectionRecord) -> None:
        self.record = record

    def save(self, user_id: str, record: DexcomConnectionRecord) -> None:
        self.record = replace(record)


class _FakeDexcomService:
    def __init__(self, record: DexcomConnectionRecord) -> None:
        self.record = record
        self.store = _FakeDexcomStore(record)

    def get_authenticated_record(self, user_id: str) -> DexcomConnectionRecord:
        return self.record

    def get_record(self, user_id: str) -> DexcomConnectionRecord:
        return self.record


class _FakeDexcomClient:
    def __init__(self, data_range: DexcomDataRange, readings: list[DexcomEGVReading]) -> None:
        self.data_range = data_range
        self.readings = readings
        self.calls: list[tuple[datetime, datetime]] = []

    def fetch_data_range(self, access_token: str, last_sync_time: datetime | None = None) -> DexcomDataRange:
        return self.data_range

    def fetch_egvs(self, access_token: str, start: datetime, end: datetime) -> list[DexcomEGVReading]:
        self.calls.append((start, end))
        return list(self.readings)


def test_sync_recent_glucose_backfills_when_no_local_rows_even_with_last_sync(tmp_path) -> None:
    user_id = "user-1"
    end = datetime(2026, 5, 16, 16, 59, 2, tzinfo=UTC)
    record = DexcomConnectionRecord(
        status="connected",
        access_token="token",
        last_sync_at=datetime(2026, 5, 16, 16, 57, 14, tzinfo=UTC),
    )
    readings = [
        DexcomEGVReading(
            timestamp=datetime(2026, 5, 16, 15, 54, 2, tzinfo=UTC),
            value_mgdl=121,
            trend="flat",
            provider_record_id="r1",
        ),
        DexcomEGVReading(
            timestamp=datetime(2026, 5, 16, 15, 59, 2, tzinfo=UTC),
            value_mgdl=135,
            trend="fortyFiveUp",
            provider_record_id="r2",
        ),
    ]
    service = _FakeDexcomService(record)
    client = _FakeDexcomClient(
        DexcomDataRange(egvs=DexcomDataRangeWindow(start=end - timedelta(days=180), end=end)),
        readings,
    )
    glucose_store = SQLiteGlucoseStore(tmp_path / "glucose.sqlite3")
    cgm_service = CGMService(service, client, glucose_store)

    result = cgm_service.sync_recent_glucose(user_id)

    assert result.synced_count == 2
    assert client.calls[0][0] == end - timedelta(days=7)
    persisted = glucose_store.fetch_readings(user_id, end - timedelta(days=7), end)
    assert len(persisted) == 2
    assert service.store.record.last_sync_at == readings[-1].timestamp


def test_sync_recent_glucose_does_not_advance_cursor_when_no_new_readings(tmp_path) -> None:
    user_id = "user-2"
    existing_cursor = datetime(2026, 5, 16, 15, 59, 2, tzinfo=UTC)
    record = DexcomConnectionRecord(
        status="connected",
        access_token="token",
        last_sync_at=existing_cursor,
    )
    service = _FakeDexcomService(record)
    client = _FakeDexcomClient(
        DexcomDataRange(
            egvs=DexcomDataRangeWindow(
                start=datetime(2026, 5, 15, 0, 0, tzinfo=UTC),
                end=datetime(2026, 5, 16, 16, 59, 2, tzinfo=UTC),
            )
        ),
        [],
    )
    glucose_store = SQLiteGlucoseStore(tmp_path / "glucose.sqlite3")
    glucose_store.upsert_readings(
        user_id,
        [
            StoredGlucoseReading(
                id="existing",
                timestamp=existing_cursor,
                value_mgdl=120,
                source="dexcom",
                trend="flat",
            )
        ],
    )
    cgm_service = CGMService(service, client, glucose_store)

    result = cgm_service.sync_recent_glucose(user_id)

    assert result.synced_count == 0
    assert client.calls[0][0] == existing_cursor - timedelta(minutes=15)
    assert service.store.record.last_sync_at == existing_cursor
