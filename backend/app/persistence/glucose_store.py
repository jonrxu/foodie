from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from threading import Lock


@dataclass
class StoredGlucoseReading:
    id: str
    timestamp: datetime
    value_mgdl: int
    source: str
    trend: str | None


class SQLiteGlucoseStore:
    def __init__(self, database_path: Path) -> None:
        self.database_path = database_path
        self._lock = Lock()
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def upsert_readings(self, user_id: str, readings: list[StoredGlucoseReading]) -> None:
        if not readings:
            return

        with self._lock, self._connect() as connection:
            connection.executemany(
                """
                INSERT INTO glucose_readings (
                    id, user_id, timestamp, value_mgdl, source, trend
                ) VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    user_id = excluded.user_id,
                    timestamp = excluded.timestamp,
                    value_mgdl = excluded.value_mgdl,
                    source = excluded.source,
                    trend = excluded.trend
                """,
                [
                    (
                        reading.id,
                        user_id,
                        self._serialize_datetime(reading.timestamp),
                        reading.value_mgdl,
                        reading.source,
                        reading.trend,
                    )
                    for reading in readings
                ],
            )
            connection.commit()

    def fetch_readings(
        self,
        user_id: str,
        start: datetime,
        end: datetime,
    ) -> list[StoredGlucoseReading]:
        with self._lock, self._connect() as connection:
            rows = connection.execute(
                """
                SELECT id, timestamp, value_mgdl, source, trend
                FROM glucose_readings
                WHERE user_id = ?
                  AND timestamp >= ?
                  AND timestamp <= ?
                ORDER BY timestamp ASC
                """,
                (
                    user_id,
                    self._serialize_datetime(start),
                    self._serialize_datetime(end),
                ),
            ).fetchall()
        return [self._row_to_reading(row) for row in rows]

    def _initialize(self) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS glucose_readings (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    value_mgdl INTEGER NOT NULL,
                    source TEXT NOT NULL,
                    trend TEXT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_glucose_user_timestamp
                ON glucose_readings (user_id, timestamp)
                """
            )
            connection.commit()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.database_path)
        connection.row_factory = sqlite3.Row
        return connection

    @staticmethod
    def _serialize_datetime(value: datetime) -> str:
        return value.astimezone(UTC).isoformat()

    @staticmethod
    def _deserialize_datetime(value: str) -> datetime:
        parsed = datetime.fromisoformat(value)
        if parsed.tzinfo is None:
            return parsed.replace(tzinfo=UTC)
        return parsed.astimezone(UTC)

    def _row_to_reading(self, row: sqlite3.Row) -> StoredGlucoseReading:
        return StoredGlucoseReading(
            id=str(row["id"]),
            timestamp=self._deserialize_datetime(str(row["timestamp"])),
            value_mgdl=int(row["value_mgdl"]),
            source=str(row["source"]),
            trend=row["trend"],
        )
