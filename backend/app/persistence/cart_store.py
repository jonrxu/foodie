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
class StoredCartDraft:
    id: str
    source: str
    created_at: datetime
    updated_at: datetime
    payload: dict[str, Any]


class SQLiteCartStore:
    def __init__(self, database_path: Path) -> None:
        self.database_path = database_path
        self._lock = Lock()
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def upsert_draft(self, user_id: str, draft: StoredCartDraft) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                INSERT INTO cart_drafts (
                    id, user_id, source, created_at, updated_at, payload_json
                ) VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    user_id = excluded.user_id,
                    source = excluded.source,
                    created_at = excluded.created_at,
                    updated_at = excluded.updated_at,
                    payload_json = excluded.payload_json
                """,
                (
                    draft.id,
                    user_id,
                    draft.source,
                    self._serialize_datetime(draft.created_at),
                    self._serialize_datetime(draft.updated_at),
                    json.dumps(draft.payload),
                ),
            )
            connection.commit()

    def fetch_latest_draft(self, user_id: str) -> StoredCartDraft | None:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                """
                SELECT id, source, created_at, updated_at, payload_json
                FROM cart_drafts
                WHERE user_id = ?
                ORDER BY updated_at DESC
                LIMIT 1
                """,
                (user_id,),
            ).fetchone()
        return self._row_to_draft(row) if row else None

    def fetch_draft(self, user_id: str, draft_id: UUID | str) -> StoredCartDraft | None:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                """
                SELECT id, source, created_at, updated_at, payload_json
                FROM cart_drafts
                WHERE user_id = ? AND id = ?
                """,
                (user_id, str(draft_id)),
            ).fetchone()
        return self._row_to_draft(row) if row else None

    def _initialize(self) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS cart_drafts (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    source TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    payload_json TEXT NOT NULL
                )
                """
            )
            connection.execute(
                """
                CREATE INDEX IF NOT EXISTS idx_cart_drafts_user_updated_at
                ON cart_drafts (user_id, updated_at)
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

    def _row_to_draft(self, row: sqlite3.Row) -> StoredCartDraft:
        return StoredCartDraft(
            id=str(row["id"]),
            source=str(row["source"]),
            created_at=self._deserialize_datetime(str(row["created_at"])),
            updated_at=self._deserialize_datetime(str(row["updated_at"])),
            payload=json.loads(str(row["payload_json"])),
        )
