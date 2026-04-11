from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

from app.api.errors import AppError
from app.persistence.user_store import SQLiteUserStore, StoredUser
from app.schemas.users import UserProfileResponse, UserRegistrationRequest


class UserService:
    def __init__(self, user_store: SQLiteUserStore) -> None:
        self.user_store = user_store

    def register_user(self, request: UserRegistrationRequest) -> UserProfileResponse:
        now = datetime.now(UTC)
        user_id = str(uuid4())
        self.user_store.create_user(
            StoredUser(
                id=user_id,
                display_name=request.displayName,
                diet_preferences=request.dietPreferences,
                care_goals=request.careGoals,
                support_preferences=request.supportPreferences,
                created_at=now,
            )
        )
        return UserProfileResponse(
            id=user_id,
            displayName=request.displayName,
            dietPreferences=request.dietPreferences,
            careGoals=request.careGoals,
            supportPreferences=request.supportPreferences,
            createdAt=now,
        )

    def get_user(self, user_id: str) -> UserProfileResponse:
        stored = self.user_store.fetch_user(user_id)
        if stored is None:
            raise AppError(code="user_not_found", message="User profile not found.", status_code=404)
        return UserProfileResponse(
            id=stored.id,
            displayName=stored.display_name,
            dietPreferences=stored.diet_preferences,
            careGoals=stored.care_goals,
            supportPreferences=stored.support_preferences,
            createdAt=stored.created_at,
        )
