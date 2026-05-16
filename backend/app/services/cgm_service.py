from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta

from app.clients.dexcom_client import DexcomApiClient
from app.persistence.glucose_store import SQLiteGlucoseStore, StoredGlucoseReading
from app.schemas.cgm import (
    GlucoseReadingResponse,
    GlucoseReadingsResponse,
    GlucoseSummaryPayload,
    WeeklyGlucoseSummaryResponse,
)
from app.services.dexcom_service import DexcomService


@dataclass
class SyncResult:
    synced_count: int
    synced_at: datetime


class CGMService:
    TARGET_LOW_MGDL = 70
    TARGET_HIGH_MGDL = 180

    def __init__(
        self,
        dexcom_service: DexcomService,
        dexcom_client: DexcomApiClient,
        glucose_store: SQLiteGlucoseStore,
    ) -> None:
        self.dexcom_service = dexcom_service
        self.dexcom_client = dexcom_client
        self.glucose_store = glucose_store

    def sync_recent_glucose(self, user_id: str) -> SyncResult:
        record = self.dexcom_service.get_authenticated_record(user_id)
        access_token = record.access_token
        assert access_token is not None

        data_range = self.dexcom_client.fetch_data_range(
            access_token=access_token,
            last_sync_time=record.last_sync_at,
        )

        if not data_range.egvs:
            now = datetime.now(UTC)
            return SyncResult(synced_count=0, synced_at=now)

        end = data_range.egvs.end
        has_local_readings = self.glucose_store.has_readings(user_id)
        if record.last_sync_at and has_local_readings:
            start = max(data_range.egvs.start, record.last_sync_at - timedelta(minutes=15))
        else:
            start = max(data_range.egvs.start, end - timedelta(days=7))

        egvs = self.dexcom_client.fetch_egvs(access_token=access_token, start=start, end=end)
        stored = [
            StoredGlucoseReading(
                id=f"{user_id}:{reading.provider_record_id}",
                timestamp=reading.timestamp,
                value_mgdl=reading.value_mgdl,
                source="dexcom",
                trend=self._map_trend(reading.trend),
            )
            for reading in egvs
        ]
        self.glucose_store.upsert_readings(user_id, stored)

        synced_at = datetime.now(UTC)
        if egvs:
            record.last_sync_at = max(reading.timestamp for reading in egvs)
        self.dexcom_service.store.save(user_id, record)
        return SyncResult(synced_count=len(stored), synced_at=synced_at)

    def fetch_weekly_summary(self, user_id: str, anchor_date: date | None = None) -> WeeklyGlucoseSummaryResponse:
        summary = self._build_weekly_summary(user_id=user_id, anchor_date=anchor_date)
        return WeeklyGlucoseSummaryResponse(summary=summary)

    def fetch_readings(
        self,
        user_id: str,
        start: datetime,
        end: datetime,
    ) -> GlucoseReadingsResponse:
        readings = self._load_window(user_id=user_id, start=start, end=end)
        return GlucoseReadingsResponse(readings=readings)

    def _build_weekly_summary(self, user_id: str, anchor_date: date | None) -> GlucoseSummaryPayload:
        anchor = anchor_date or datetime.now(UTC).date()
        end = datetime.combine(anchor, time.max, tzinfo=UTC)
        start = end - timedelta(days=7)
        readings = self._load_window(user_id=user_id, start=start, end=end)

        if not readings:
            connection = self.dexcom_service.get_record(user_id)
            if connection.status == "connected":
                try:
                    self.sync_recent_glucose(user_id)
                    readings = self._load_window(user_id=user_id, start=start, end=end)
                except Exception:
                    pass

        average = None
        time_in_range = None
        if readings:
            values = [reading.valueMgdl for reading in readings]
            average = round(sum(values) / len(values), 1)
            in_range = [
                value
                for value in values
                if self.TARGET_LOW_MGDL <= value <= self.TARGET_HIGH_MGDL
            ]
            time_in_range = round((len(in_range) / len(values)) * 100)

        return GlucoseSummaryPayload(
            startDate=start,
            endDate=end,
            targetLowMgdl=self.TARGET_LOW_MGDL,
            targetHighMgdl=self.TARGET_HIGH_MGDL,
            averageMgdl=average,
            timeInRangePercent=time_in_range,
            readings=readings,
        )

    def _load_window(self, user_id: str, start: datetime, end: datetime) -> list[GlucoseReadingResponse]:
        stored = self.glucose_store.fetch_readings(user_id=user_id, start=start, end=end)
        return [
            GlucoseReadingResponse(
                id=reading.id,
                timestamp=reading.timestamp,
                valueMgdl=reading.value_mgdl,
                source=reading.source,
                trend=reading.trend,
            )
            for reading in stored
        ]

    @staticmethod
    def _map_trend(value: str | None) -> str | None:
        if not value:
            return None

        mapping = {
            "doubleUp": "doubleUp",
            "singleUp": "singleUp",
            "flat": "flat",
            "singleDown": "singleDown",
            "doubleDown": "doubleDown",
            "fortyFiveUp": "singleUp",
            "fortyFiveDown": "singleDown",
        }
        return mapping.get(value, "unknown")
