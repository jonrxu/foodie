from __future__ import annotations

import json
import sqlite3
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from threading import Lock


@dataclass
class StoredUser:
    id: str
    email: str | None
    display_name: str
    diet_preferences: list[str]
    care_goals: list[str]
    support_preferences: list[str]
    has_completed_onboarding: bool
    created_at: datetime


class SQLiteUserStore:
    def __init__(self, database_path: Path) -> None:
        self.database_path = database_path
        self._lock = Lock()
        self.database_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def create_user(self, user: StoredUser) -> None:
        with self._lock, self._connect() as conn:
            conn.execute(
                """
                INSERT INTO users (
                    id, email, display_name, diet_preferences, care_goals, support_preferences,
                    has_completed_onboarding, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO NOTHING
                """,
                (
                    user.id,
                    user.email,
                    user.display_name,
                    json.dumps(user.diet_preferences),
                    json.dumps(user.care_goals),
                    json.dumps(user.support_preferences),
                    1 if user.has_completed_onboarding else 0,
                    user.created_at.astimezone(UTC).isoformat(),
                ),
            )
            conn.commit()

    def upsert_user(self, user: StoredUser) -> None:
        with self._lock, self._connect() as conn:
            conn.execute(
                """
                INSERT INTO users (
                    id, email, display_name, diet_preferences, care_goals, support_preferences,
                    has_completed_onboarding, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    email = excluded.email,
                    display_name = excluded.display_name,
                    diet_preferences = excluded.diet_preferences,
                    care_goals = excluded.care_goals,
                    support_preferences = excluded.support_preferences,
                    has_completed_onboarding = excluded.has_completed_onboarding
                """,
                (
                    user.id,
                    user.email,
                    user.display_name,
                    json.dumps(user.diet_preferences),
                    json.dumps(user.care_goals),
                    json.dumps(user.support_preferences),
                    1 if user.has_completed_onboarding else 0,
                    user.created_at.astimezone(UTC).isoformat(),
                ),
            )
            conn.commit()

    def list_user_ids(self) -> list[str]:
        with self._lock, self._connect() as conn:
            rows = conn.execute("SELECT id FROM users").fetchall()
        return [str(row["id"]) for row in rows]

    def fetch_user(self, user_id: str) -> StoredUser | None:
        with self._lock, self._connect() as conn:
            row = conn.execute(
                """
                SELECT id, email, display_name, diet_preferences, care_goals, support_preferences,
                       has_completed_onboarding, created_at
                FROM users WHERE id = ?
                """,
                (user_id,),
            ).fetchone()
        return self._row_to_user(row) if row else None

    def _initialize(self) -> None:
        with self._lock, self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    email TEXT NULL,
                    display_name TEXT NOT NULL DEFAULT '',
                    diet_preferences TEXT NOT NULL DEFAULT '[]',
                    care_goals TEXT NOT NULL DEFAULT '[]',
                    support_preferences TEXT NOT NULL DEFAULT '[]',
                    has_completed_onboarding INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL
                )
                """
            )
            existing_columns = {
                str(row["name"])
                for row in conn.execute("PRAGMA table_info(users)").fetchall()
            }
            if "email" not in existing_columns:
                conn.execute("ALTER TABLE users ADD COLUMN email TEXT NULL")
            if "has_completed_onboarding" not in existing_columns:
                conn.execute(
                    "ALTER TABLE users ADD COLUMN has_completed_onboarding INTEGER NOT NULL DEFAULT 0"
                )
            conn.commit()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.database_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _row_to_user(self, row: sqlite3.Row) -> StoredUser:
        created_at = datetime.fromisoformat(str(row["created_at"]))
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=UTC)
        return StoredUser(
            id=str(row["id"]),
            email=str(row["email"]) if row["email"] is not None else None,
            display_name=str(row["display_name"]),
            diet_preferences=json.loads(str(row["diet_preferences"])),
            care_goals=json.loads(str(row["care_goals"])),
            support_preferences=json.loads(str(row["support_preferences"])),
            has_completed_onboarding=bool(row["has_completed_onboarding"]),
            created_at=created_at,
        )
