from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from app.api.errors import AppError
from app.persistence.user_store import SQLiteUserStore, StoredUser
from app.schemas.users import UserProfileResponse, UserProfileUpdateRequest


class UserService:
    def __init__(self, user_store: SQLiteUserStore) -> None:
        self.user_store = user_store

    def get_user(self, user_id: str) -> UserProfileResponse:
        stored = self.user_store.fetch_user(user_id)
        if stored is None:
            raise AppError(code="user_not_found", message="User profile not found.", status_code=404)
        return self._to_response(stored)

    def get_or_create_authenticated_user(self, current_user: Any) -> UserProfileResponse:
        stored = self.user_store.fetch_user(current_user.id)
        if stored is None:
            stored = StoredUser(
                id=current_user.id,
                email=current_user.email,
                display_name="",
                diet_preferences=[],
                care_goals=[],
                support_preferences=[],
                has_completed_onboarding=False,
                created_at=datetime.now(UTC),
            )
            self.user_store.upsert_user(stored)
            return self._to_response(stored)

        if current_user.email and stored.email != current_user.email:
            stored.email = current_user.email
            self.user_store.upsert_user(stored)

        return self._to_response(stored)

    def update_authenticated_user(
        self,
        current_user: Any,
        request: UserProfileUpdateRequest,
    ) -> UserProfileResponse:
        return self.update_user(
            user_id=current_user.id,
            email=current_user.email,
            request=request,
        )

    def update_user(
        self,
        user_id: str,
        request: UserProfileUpdateRequest,
        email: str | None = None,
    ) -> UserProfileResponse:
        existing = self.user_store.fetch_user(user_id)
        now = datetime.now(UTC)
        stored = StoredUser(
            id=user_id,
            email=email if email is not None else (existing.email if existing is not None else None),
            display_name=request.displayName,
            diet_preferences=request.dietPreferences,
            care_goals=request.careGoals,
            support_preferences=request.supportPreferences,
            has_completed_onboarding=request.hasCompletedOnboarding,
            created_at=existing.created_at if existing is not None else now,
        )
        self.user_store.upsert_user(stored)
        return self._to_response(stored)

    def _to_response(self, stored: StoredUser) -> UserProfileResponse:
        return UserProfileResponse(
            id=stored.id,
            email=stored.email,
            displayName=stored.display_name,
            dietPreferences=stored.diet_preferences,
            careGoals=stored.care_goals,
            supportPreferences=stored.support_preferences,
            hasCompletedOnboarding=stored.has_completed_onboarding,
            createdAt=stored.created_at,
        )
