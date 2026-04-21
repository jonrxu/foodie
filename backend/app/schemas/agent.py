from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


AgentRunKind = Literal["spike_triggered", "daily_summary", "weekly_planning"]
AgentRunStatus = Literal["completed", "skipped", "failed"]
NotificationKind = Literal["log_meal_prompt", "meal_feedback_ready", "daily_summary_ready", "weekly_plan_ready"]


class NotificationDraftPayload(BaseModel):
    id: UUID
    kind: NotificationKind
    title: str
    body: str
    createdAt: datetime
    actionLabel: str | None = None
    targetPath: str | None = None
    relatedMealLogID: UUID | None = None


class AgentRecommendationPayload(BaseModel):
    id: UUID
    createdAt: datetime
    runKind: AgentRunKind
    title: str
    summary: str
    actionLabel: str | None = None
    relatedMealLogID: UUID | None = None
    relatedSpikeStartedAt: datetime | None = None
    readAt: datetime | None = None
    dismissedAt: datetime | None = None
    notificationDraft: NotificationDraftPayload | None = None


class AgentRunPayload(BaseModel):
    id: UUID
    kind: AgentRunKind
    status: AgentRunStatus
    createdAt: datetime
    completedAt: datetime | None = None
    summary: str
    sourceEventKey: str | None = None
    recommendationsCreated: int = 0


class AgentFeedResponse(BaseModel):
    runs: list[AgentRunPayload] = Field(default_factory=list)
    recommendations: list[AgentRecommendationPayload] = Field(default_factory=list)


class AgentRecommendationStateResponse(BaseModel):
    id: UUID
    readAt: datetime | None = None
    dismissedAt: datetime | None = None
