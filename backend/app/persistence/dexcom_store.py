from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from threading import Lock


@dataclass
class DexcomConnectionRecord:
    status: str = "disconnected"
    connected_at: datetime | None = None
    last_sync_at: datetime | None = None
    error_message: str | None = None
    pending_state: str | None = None
    pending_started_at: datetime | None = None
    access_token: str | None = None
    refresh_token: str | None = None
    token_type: str | None = None
    expires_at: datetime | None = None


class SQLiteDexcomConnectionStore:
    """SQLite-backed Dexcom connection store.

    This is a prototype persistence layer and will be replaced by Postgres-backed
    repositories when the broader backend data model lands.
    """

    def __init__(self, database_path: Path) -> None:
        self.database_path = database_path
        self._lock = Lock()
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def get(self, user_id: str) -> DexcomConnectionRecord:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                """
                SELECT status, connected_at, last_sync_at, error_message,
                       pending_state, pending_started_at,
                       access_token, refresh_token, token_type, expires_at
                FROM dexcom_connections
                WHERE user_id = ?
                """,
                (user_id,),
            ).fetchone()
        return self._row_to_record(row) if row else DexcomConnectionRecord()

    def save(self, user_id: str, record: DexcomConnectionRecord) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                INSERT INTO dexcom_connections (
                    user_id, status, connected_at, last_sync_at, error_message,
                    pending_state, pending_started_at,
                    access_token, refresh_token, token_type, expires_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(user_id) DO UPDATE SET
                    status = excluded.status,
                    connected_at = excluded.connected_at,
                    last_sync_at = excluded.last_sync_at,
                    error_message = excluded.error_message,
                    pending_state = excluded.pending_state,
                    pending_started_at = excluded.pending_started_at,
                    access_token = excluded.access_token,
                    refresh_token = excluded.refresh_token,
                    token_type = excluded.token_type,
                    expires_at = excluded.expires_at
                """,
                (
                    user_id,
                    record.status,
                    self._serialize_datetime(record.connected_at),
                    self._serialize_datetime(record.last_sync_at),
                    record.error_message,
                    record.pending_state,
                    self._serialize_datetime(record.pending_started_at),
                    record.access_token,
                    record.refresh_token,
                    record.token_type,
                    self._serialize_datetime(record.expires_at),
                ),
            )
            connection.commit()

    def resolve_user_by_state(self, state: str) -> str | None:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                "SELECT user_id FROM dexcom_connections WHERE pending_state = ?",
                (state,),
            ).fetchone()
        return str(row["user_id"]) if row else None

    def remove_state(self, state: str) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                UPDATE dexcom_connections
                SET pending_state = NULL,
                    pending_started_at = NULL
                WHERE pending_state = ?
                """,
                (state,),
            )
            connection.commit()

    def _initialize(self) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS dexcom_connections (
                    user_id TEXT PRIMARY KEY,
                    status TEXT NOT NULL,
                    connected_at TEXT NULL,
                    last_sync_at TEXT NULL,
                    error_message TEXT NULL,
                    pending_state TEXT NULL UNIQUE,
                    pending_started_at TEXT NULL,
                    access_token TEXT NULL,
                    refresh_token TEXT NULL,
                    token_type TEXT NULL,
                    expires_at TEXT NULL
                )
                """
            )
            connection.commit()

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.database_path)
        connection.row_factory = sqlite3.Row
        return connection

    @staticmethod
    def _serialize_datetime(value: datetime | None) -> str | None:
        return value.isoformat() if value else None

    @staticmethod
    def _deserialize_datetime(value: str | None) -> datetime | None:
        return datetime.fromisoformat(value) if value else None

    def _row_to_record(self, row: sqlite3.Row) -> DexcomConnectionRecord:
        return DexcomConnectionRecord(
            status=str(row["status"]),
            connected_at=self._deserialize_datetime(row["connected_at"]),
            last_sync_at=self._deserialize_datetime(row["last_sync_at"]),
            error_message=row["error_message"],
            pending_state=row["pending_state"],
            pending_started_at=self._deserialize_datetime(row["pending_started_at"]),
            access_token=row["access_token"],
            refresh_token=row["refresh_token"],
            token_type=row["token_type"],
            expires_at=self._deserialize_datetime(row["expires_at"]),
        )
