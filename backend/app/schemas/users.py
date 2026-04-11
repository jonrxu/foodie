from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class UserRegistrationRequest(BaseModel):
    displayName: str = ""
    dietPreferences: list[str] = []
    careGoals: list[str] = []
    supportPreferences: list[str] = []


class UserProfileResponse(BaseModel):
    id: str
    displayName: str
    dietPreferences: list[str]
    careGoals: list[str]
    supportPreferences: list[str]
    createdAt: datetime
