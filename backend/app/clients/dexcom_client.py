from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from math import sin
from typing import Any

import httpx

from app.api.errors import AppError
from app.config.settings import Settings


@dataclass
class DexcomDataRangeWindow:
    start: datetime
    end: datetime


@dataclass
class DexcomDataRange:
    egvs: DexcomDataRangeWindow | None


@dataclass
class DexcomEGVReading:
    timestamp: datetime
    value_mgdl: int
    trend: str | None
    provider_record_id: str


class DexcomApiClient:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    def fetch_data_range(self, access_token: str, last_sync_time: datetime | None = None) -> DexcomDataRange:
        if self._use_mock_mode():
            now = datetime.now(UTC).replace(second=0, microsecond=0)
            return DexcomDataRange(
                egvs=DexcomDataRangeWindow(
                    start=now - timedelta(days=7),
                    end=now,
                )
            )

        params: dict[str, str] = {}
        if last_sync_time:
            params["lastSyncTime"] = self._format_dexcom_datetime(last_sync_time)

        response = self._get("/v3/users/self/dataRange", access_token=access_token, params=params)
        payload = response.json()
        egvs = payload.get("egvs")
        return DexcomDataRange(
            egvs=(
                DexcomDataRangeWindow(
                    start=self._parse_dexcom_datetime(egvs["start"]["systemTime"]),
                    end=self._parse_dexcom_datetime(egvs["end"]["systemTime"]),
                )
                if egvs
                else None
            )
        )

    def fetch_egvs(self, access_token: str, start: datetime, end: datetime) -> list[DexcomEGVReading]:
        if self._use_mock_mode():
            return self._generate_mock_egvs(start=start, end=end)

        response = self._get(
            "/v3/users/self/egvs",
            access_token=access_token,
            params={
                "startDate": self._format_dexcom_datetime(start),
                "endDate": self._format_dexcom_datetime(end),
            },
        )
        payload = response.json()
        egvs_payload = payload.get("egvs", [])

        readings: list[DexcomEGVReading] = []
        for item in egvs_payload:
            system_time = item.get("systemTime")
            if not system_time:
                continue

            value = item.get("value")
            if value is None:
                continue

            record_id = item.get("realtimeValue") or system_time
            readings.append(
                DexcomEGVReading(
                    timestamp=self._parse_dexcom_datetime(system_time),
                    value_mgdl=int(value),
                    trend=item.get("trend"),
                    provider_record_id=str(record_id),
                )
            )
        return readings

    def _get(self, path: str, access_token: str, params: dict[str, str]) -> httpx.Response:
        base = str(self.settings.dexcom_api_base).rstrip("/")
        try:
            response = httpx.get(
                f"{base}{path}",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Accept": "application/json",
                },
                params=params,
                timeout=10.0,
            )
        except httpx.HTTPError as exc:
            raise AppError(
                code="dexcom_request_failed",
                message="Dexcom request failed",
                status_code=502,
            ) from exc

        if response.status_code == 401:
            raise AppError(
                code="dexcom_unauthorized",
                message="Dexcom access token is no longer valid",
                status_code=401,
            )

        if response.status_code >= 400:
            try:
                body = response.json()
            except Exception:
                body = response.text
            raise AppError(
                code="dexcom_request_failed",
                message=f"Dexcom request failed with status {response.status_code}: {body}",
                status_code=502,
            )

        return response

    def _generate_mock_egvs(self, start: datetime, end: datetime) -> list[DexcomEGVReading]:
        readings: list[DexcomEGVReading] = []
        current = start.astimezone(UTC).replace(second=0, microsecond=0)
        index = 0
        while current <= end:
            baseline = 132 + int(18 * sin(index / 5.5))
            meal_bump = 0
            hour = current.hour
            if hour in {8, 13, 19}:
                meal_bump = 28
            elif hour in {9, 14, 20}:
                meal_bump = 18

            value = max(82, min(205, baseline + meal_bump))
            trend = self._mock_trend(index)
            readings.append(
                DexcomEGVReading(
                    timestamp=current,
                    value_mgdl=value,
                    trend=trend,
                    provider_record_id=current.isoformat(),
                )
            )
            current += timedelta(minutes=15)
            index += 1
        return readings

    @staticmethod
    def _mock_trend(index: int) -> str:
        cycle = index % 10
        if cycle in {0, 1}:
            return "singleUp"
        if cycle in {2, 3, 4, 5}:
            return "flat"
        return "singleDown"

    def _use_mock_mode(self) -> bool:
        return self.settings.dexcom_mock_oauth or self._has_placeholder_credentials()

    def _has_placeholder_credentials(self) -> bool:
        return (
            self.settings.dexcom_client_id == "replace-me"
            or self.settings.dexcom_client_secret == "replace-me"
        )

    @staticmethod
    def _format_dexcom_datetime(value: datetime) -> str:
        return value.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%S")

    @staticmethod
    def _parse_dexcom_datetime(value: str) -> datetime:
        normalized = value.replace("Z", "+00:00")
        parsed = datetime.fromisoformat(normalized)
        if parsed.tzinfo is None:
            return parsed.replace(tzinfo=UTC)
        return parsed.astimezone(UTC)
