from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class UserProfileUpdateRequest(BaseModel):
    displayName: str = ""
    dietPreferences: list[str] = []
    careGoals: list[str] = []
    supportPreferences: list[str] = []
    hasCompletedOnboarding: bool = False


class UserProfileResponse(BaseModel):
    id: str
    email: str | None = None
    displayName: str
    dietPreferences: list[str]
    careGoals: list[str]
    supportPreferences: list[str]
    hasCompletedOnboarding: bool
    createdAt: datetime
