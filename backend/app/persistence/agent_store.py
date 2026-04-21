from __future__ import annotations

import json
import sqlite3
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from threading import Lock
from typing import Any


@dataclass
class StoredAgentRun:
    id: str
    kind: str
    status: str
    created_at: datetime
    completed_at: datetime | None
    summary: str
    source_event_key: str | None
    recommendations_created: int


@dataclass
class StoredAgentRecommendation:
    id: str
    run_id: str
    created_at: datetime
    title: str
    summary: str
    read_at: datetime | None
    dismissed_at: datetime | None
    payload: dict[str, Any]


class SQLiteAgentStore:
    def __init__(self, database_path: Path) -> None:
        self.database_path = database_path
        self._lock = Lock()
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def has_run_for_source_event(self, user_id: str, kind: str, source_event_key: str) -> bool:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                """
                SELECT 1
                FROM agent_runs
                WHERE user_id = ? AND kind = ? AND source_event_key = ?
                LIMIT 1
                """,
                (user_id, kind, source_event_key),
            ).fetchone()
        return row is not None

    def insert_run(self, user_id: str, run: StoredAgentRun) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                INSERT INTO agent_runs (
                    id, user_id, kind, status, created_at, completed_at, summary, source_event_key, recommendations_created
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    run.id,
                    user_id,
                    run.kind,
                    run.status,
                    self._serialize_datetime(run.created_at),
                    self._serialize_datetime(run.completed_at) if run.completed_at else None,
                    run.summary,
                    run.source_event_key,
                    run.recommendations_created,
                ),
            )
            connection.commit()

    def insert_recommendation(
        self,
        user_id: str,
        recommendation: StoredAgentRecommendation,
        notification_payload: dict[str, Any] | None,
    ) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                INSERT INTO agent_recommendations (
                    id, user_id, run_id, created_at, title, summary, read_at, dismissed_at, payload_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    recommendation.id,
                    user_id,
                    recommendation.run_id,
                    self._serialize_datetime(recommendation.created_at),
                    recommendation.title,
                    recommendation.summary,
                    self._serialize_datetime(recommendation.read_at) if recommendation.read_at else None,
                    self._serialize_datetime(recommendation.dismissed_at) if recommendation.dismissed_at else None,
                    json.dumps(recommendation.payload),
                ),
            )
            if notification_payload is not None:
                connection.execute(
                    """
                    INSERT INTO notification_drafts (
                        id, user_id, recommendation_id, created_at, payload_json
                    ) VALUES (?, ?, ?, ?, ?)
                    """,
                    (
                        str(notification_payload["id"]),
                        user_id,
                        recommendation.id,
                        self._serialize_datetime(recommendation.created_at),
                        json.dumps(notification_payload),
                    ),
                )
            connection.commit()

    def fetch_recent_runs(self, user_id: str, limit: int = 20) -> list[StoredAgentRun]:
        with self._lock, self._connect() as connection:
            rows = connection.execute(
                """
                SELECT id, kind, status, created_at, completed_at, summary, source_event_key, recommendations_created
                FROM agent_runs
                WHERE user_id = ?
                ORDER BY created_at DESC
                LIMIT ?
                """,
                (user_id, limit),
            ).fetchall()
        return [self._row_to_run(row) for row in rows]

    def fetch_runs_between(
        self,
        user_id: str,
        start: datetime,
        end: datetime,
        *,
        kind: str | None = None,
    ) -> list[StoredAgentRun]:
        query = """
            SELECT id, kind, status, created_at, completed_at, summary, source_event_key, recommendations_created
            FROM agent_runs
            WHERE user_id = ?
              AND created_at >= ?
              AND created_at <= ?
        """
        params: list[Any] = [
            user_id,
            self._serialize_datetime(start),
            self._serialize_datetime(end),
        ]
        if kind is not None:
            query += " AND kind = ?"
            params.append(kind)
        query += " ORDER BY created_at DESC"
        with self._lock, self._connect() as connection:
            rows = connection.execute(query, params).fetchall()
        return [self._row_to_run(row) for row in rows]

    def fetch_recent_recommendations(self, user_id: str, limit: int = 20) -> list[dict[str, Any]]:
        with self._lock, self._connect() as connection:
            rows = connection.execute(
                """
                SELECT
                    r.id,
                    r.run_id,
                    r.created_at,
                    r.title,
                    r.summary,
                    r.read_at,
                    r.dismissed_at,
                    r.payload_json,
                    n.payload_json AS notification_payload
                FROM agent_recommendations r
                LEFT JOIN notification_drafts n
                  ON n.recommendation_id = r.id
                WHERE r.user_id = ?
                ORDER BY r.created_at DESC
                LIMIT ?
                """,
                (user_id, limit),
            ).fetchall()
        return [
            {
                "id": str(row["id"]),
                "run_id": str(row["run_id"]),
                "created_at": self._deserialize_datetime(str(row["created_at"])),
                "title": str(row["title"]),
                "summary": str(row["summary"]),
                "read_at": self._deserialize_datetime(str(row["read_at"])) if row["read_at"] else None,
                "dismissed_at": self._deserialize_datetime(str(row["dismissed_at"])) if row["dismissed_at"] else None,
                "payload": json.loads(str(row["payload_json"])),
                "notification_payload": json.loads(str(row["notification_payload"])) if row["notification_payload"] else None,
            }
            for row in rows
        ]

    def fetch_recommendations_between(
        self,
        user_id: str,
        start: datetime,
        end: datetime,
        *,
        run_kind: str | None = None,
    ) -> list[dict[str, Any]]:
        query = """
            SELECT
                r.id,
                r.run_id,
                r.created_at,
                r.title,
                r.summary,
                r.read_at,
                r.dismissed_at,
                r.payload_json,
                n.payload_json AS notification_payload
            FROM agent_recommendations r
            JOIN agent_runs ar
              ON ar.id = r.run_id
            LEFT JOIN notification_drafts n
              ON n.recommendation_id = r.id
            WHERE r.user_id = ?
              AND r.created_at >= ?
              AND r.created_at <= ?
        """
        params: list[Any] = [
            user_id,
            self._serialize_datetime(start),
            self._serialize_datetime(end),
        ]
        if run_kind is not None:
            query += " AND ar.kind = ?"
            params.append(run_kind)
        query += " ORDER BY r.created_at DESC"
        with self._lock, self._connect() as connection:
            rows = connection.execute(query, params).fetchall()
        return [
            {
                "id": str(row["id"]),
                "run_id": str(row["run_id"]),
                "created_at": self._deserialize_datetime(str(row["created_at"])),
                "title": str(row["title"]),
                "summary": str(row["summary"]),
                "read_at": self._deserialize_datetime(str(row["read_at"])) if row["read_at"] else None,
                "dismissed_at": self._deserialize_datetime(str(row["dismissed_at"])) if row["dismissed_at"] else None,
                "payload": json.loads(str(row["payload_json"])),
                "notification_payload": json.loads(str(row["notification_payload"])) if row["notification_payload"] else None,
            }
            for row in rows
        ]

    def fetch_recommendation(self, user_id: str, recommendation_id: str) -> StoredAgentRecommendation | None:
        with self._lock, self._connect() as connection:
            row = connection.execute(
                """
                SELECT id, run_id, created_at, title, summary, read_at, dismissed_at, payload_json
                FROM agent_recommendations
                WHERE user_id = ? AND id = ?
                """,
                (user_id, recommendation_id),
            ).fetchone()
        if row is None:
            return None
        return self._row_to_recommendation(row)

    def mark_recommendation_read(self, user_id: str, recommendation_id: str, read_at: datetime) -> StoredAgentRecommendation | None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                UPDATE agent_recommendations
                SET read_at = COALESCE(read_at, ?)
                WHERE user_id = ? AND id = ?
                """,
                (self._serialize_datetime(read_at), user_id, recommendation_id),
            )
            connection.commit()
        return self.fetch_recommendation(user_id=user_id, recommendation_id=recommendation_id)

    def dismiss_recommendation(self, user_id: str, recommendation_id: str, dismissed_at: datetime) -> StoredAgentRecommendation | None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                UPDATE agent_recommendations
                SET dismissed_at = COALESCE(dismissed_at, ?),
                    read_at = COALESCE(read_at, ?)
                WHERE user_id = ? AND id = ?
                """,
                (
                    self._serialize_datetime(dismissed_at),
                    self._serialize_datetime(dismissed_at),
                    user_id,
                    recommendation_id,
                ),
            )
            connection.commit()
        return self.fetch_recommendation(user_id=user_id, recommendation_id=recommendation_id)

    def _initialize(self) -> None:
        with self._lock, self._connect() as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS agent_runs (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    kind TEXT NOT NULL,
                    status TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    completed_at TEXT NULL,
                    summary TEXT NOT NULL,
                    source_event_key TEXT NULL,
                    recommendations_created INTEGER NOT NULL DEFAULT 0
                )
                """
            )
            connection.execute(
                """
                CREATE UNIQUE INDEX IF NOT EXISTS idx_agent_runs_user_kind_source
                ON agent_runs (user_id, kind, source_event_key)
                WHERE source_event_key IS NOT NULL
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS agent_recommendations (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    run_id TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    title TEXT NOT NULL,
                    summary TEXT NOT NULL,
                    read_at TEXT NULL,
                    dismissed_at TEXT NULL,
                    payload_json TEXT NOT NULL
                )
                """
            )
            self._ensure_column(connection, "agent_recommendations", "read_at", "TEXT NULL")
            self._ensure_column(connection, "agent_recommendations", "dismissed_at", "TEXT NULL")
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS notification_drafts (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    recommendation_id TEXT NOT NULL,
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

    def _row_to_run(self, row: sqlite3.Row) -> StoredAgentRun:
        completed_at = row["completed_at"]
        return StoredAgentRun(
            id=str(row["id"]),
            kind=str(row["kind"]),
            status=str(row["status"]),
            created_at=self._deserialize_datetime(str(row["created_at"])),
            completed_at=self._deserialize_datetime(str(completed_at)) if completed_at else None,
            summary=str(row["summary"]),
            source_event_key=str(row["source_event_key"]) if row["source_event_key"] else None,
            recommendations_created=int(row["recommendations_created"]),
        )

    def _row_to_recommendation(self, row: sqlite3.Row) -> StoredAgentRecommendation:
        return StoredAgentRecommendation(
            id=str(row["id"]),
            run_id=str(row["run_id"]),
            created_at=self._deserialize_datetime(str(row["created_at"])),
            title=str(row["title"]),
            summary=str(row["summary"]),
            read_at=self._deserialize_datetime(str(row["read_at"])) if row["read_at"] else None,
            dismissed_at=self._deserialize_datetime(str(row["dismissed_at"])) if row["dismissed_at"] else None,
            payload=json.loads(str(row["payload_json"])),
        )

    @staticmethod
    def _ensure_column(connection: sqlite3.Connection, table: str, column: str, ddl: str) -> None:
        columns = connection.execute(f"PRAGMA table_info({table})").fetchall()
        column_names = {str(row["name"]) for row in columns}
        if column not in column_names:
            connection.execute(f"ALTER TABLE {table} ADD COLUMN {column} {ddl}")
