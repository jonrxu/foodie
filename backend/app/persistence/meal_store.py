from __future__ import annotations

import json
import sqlite3
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from threading import Lock
from typing import Any
from uuid import UUID


@dataclass
class StoredMealLog:
    id: str
    logged_at: datetime
    source: str
    summary: str
    payload: dict[str, Any]


@dataclass
class StoredJSONRecord:
    meal_log_id: str
    created_at: datetime
    payload: dict[str, Any]


class SQLiteMealStore:
    def __init__(self, database_path: Path) -> None:
        self.database_path = database_path
        self._lock = Lock()
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def upsert_meal(self, user_id: str, meal: StoredMealLog) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                INSERT INTO meal_logs (
                    id, user_id, logged_at, source, summary, payload_json
                ) VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    user_id = excluded.user_id,
                    logged_at = excluded.logged_at,
                    source = excluded.source,
                    summary = excluded.summary,
                    payload_json = excluded.payload_json
                """,
                (
                    meal.id,
                    user_id,
                    self._serialize_datetime(meal.logged_at),
                    meal.source,
                    meal.summary,
                    json.dumps(meal.payload),
                ),
            )
            connection.commit()

    def fetch_meal(self, user_id: str, meal_id: UUID | str) -> StoredMealLog | None:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                """
                SELECT id, logged_at, source, summary, payload_json
                FROM meal_logs
                WHERE user_id = ? AND id = ?
                """,
                (user_id, str(meal_id)),
            ).fetchone()
        return self._row_to_meal(row) if row else None

    def fetch_recent_meals(self, user_id: str, limit: int) -> list[StoredMealLog]:
        with self._lock, self._connect() as connection:
            rows = connection.execute(
                """
                SELECT id, logged_at, source, summary, payload_json
                FROM meal_logs
                WHERE user_id = ?
                ORDER BY logged_at DESC
                LIMIT ?
                """,
                (user_id, limit),
            ).fetchall()
        return [self._row_to_meal(row) for row in rows]

    def fetch_meals_between(self, user_id: str, start: datetime, end: datetime) -> list[StoredMealLog]:
        with self._lock, self._connect() as connection:
            rows = connection.execute(
                """
                SELECT id, logged_at, source, summary, payload_json
                FROM meal_logs
                WHERE user_id = ?
                  AND logged_at >= ?
                  AND logged_at <= ?
                ORDER BY logged_at ASC
                """,
                (
                    user_id,
                    self._serialize_datetime(start),
                    self._serialize_datetime(end),
                ),
            ).fetchall()
        return [self._row_to_meal(row) for row in rows]

    def upsert_feedback(self, user_id: str, meal_log_id: UUID | str, created_at: datetime, payload: dict[str, Any]) -> None:
        self._upsert_json_record(
            table="meal_feedback",
            user_id=user_id,
            meal_log_id=str(meal_log_id),
            created_at=created_at,
            payload=payload,
        )

    def upsert_spike_event(self, user_id: str, meal_log_id: UUID | str, created_at: datetime, payload: dict[str, Any]) -> None:
        self._upsert_json_record(
            table="spike_events",
            user_id=user_id,
            meal_log_id=str(meal_log_id),
            created_at=created_at,
            payload=payload,
        )

    def fetch_feedback(self, user_id: str, meal_log_id: UUID | str) -> StoredJSONRecord | None:
        return self._fetch_json_record(table="meal_feedback", user_id=user_id, meal_log_id=str(meal_log_id))

    def fetch_spike_event(self, user_id: str, meal_log_id: UUID | str) -> StoredJSONRecord | None:
        return self._fetch_json_record(table="spike_events", user_id=user_id, meal_log_id=str(meal_log_id))

    def _upsert_json_record(
        self,
        *,
        table: str,
        user_id: str,
        meal_log_id: str,
        created_at: datetime,
        payload: dict[str, Any],
    ) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                f"""
                INSERT INTO {table} (
                    meal_log_id, user_id, created_at, payload_json
                ) VALUES (?, ?, ?, ?)
                ON CONFLICT(meal_log_id) DO UPDATE SET
                    user_id = excluded.user_id,
                    created_at = excluded.created_at,
                    payload_json = excluded.payload_json
                """,
                (
                    meal_log_id,
                    user_id,
                    self._serialize_datetime(created_at),
                    json.dumps(payload),
                ),
            )
            connection.commit()

    def _fetch_json_record(self, *, table: str, user_id: str, meal_log_id: str) -> StoredJSONRecord | None:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                f"""
                SELECT meal_log_id, created_at, payload_json
                FROM {table}
                WHERE user_id = ? AND meal_log_id = ?
                """,
                (user_id, meal_log_id),
            ).fetchone()

        if not row:
            return None

        return StoredJSONRecord(
            meal_log_id=str(row["meal_log_id"]),
            created_at=self._deserialize_datetime(str(row["created_at"])),
            payload=json.loads(str(row["payload_json"])),
        )

    def _initialize(self) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS meal_logs (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    logged_at TEXT NOT NULL,
                    source TEXT NOT NULL,
                    summary TEXT NOT NULL,
                    payload_json TEXT NOT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_meal_logs_user_logged_at
                ON meal_logs (user_id, logged_at)
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS meal_feedback (
                    meal_log_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    payload_json TEXT NOT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS spike_events (
                    meal_log_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    payload_json TEXT NOT NULL
                )
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

    def _row_to_meal(self, row: sqlite3.Row) -> StoredMealLog:
        return StoredMealLog(
            id=str(row["id"]),
            logged_at=self._deserialize_datetime(str(row["logged_at"])),
            source=str(row["source"]),
            summary=str(row["summary"]),
            payload=json.loads(str(row["payload_json"])),
        )
