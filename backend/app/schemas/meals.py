from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class MealLogPayload(BaseModel):
    id: UUID
    loggedAt: datetime
    source: str
    summary: str
    rawInput: str | None = None
    notes: str | None = None
    assets: list[dict[str, Any]] = Field(default_factory=list)
    analysis: dict[str, Any] | None = None
    servingSize: str | None = None


class RecentMealsResponse(BaseModel):
    meals: list[MealLogPayload]


class SpikeMetricsPayload(BaseModel):
    baselineMgdl: float
    peakMgdl: float
    deltaMgdl: float
    timeToPeakMinutes: int | None = None
    returnToRangeMinutes: int | None = None


class SpikeEventPayload(BaseModel):
    id: UUID
    mealLogID: UUID
    createdAt: datetime
    eventKind: str
    status: str
    startedAt: datetime
    peakAt: datetime | None = None
    resolvedAt: datetime | None = None
    confidence: float
    metrics: SpikeMetricsPayload
    notes: list[str] = Field(default_factory=list)


class MealFeedbackPayload(BaseModel):
    id: UUID
    mealLogID: UUID
    createdAt: datetime
    mode: str
    headline: str
    summary: str
    coachMessage: str
    suggestedSwap: str | None = None
    linkedSpikeEventID: UUID | None = None
    suggestedCartItems: list[str] = Field(default_factory=list)


class MealImpactPointPayload(BaseModel):
    minute: float
    glucose: float


class MealImpactChartPayload(BaseModel):
    withMeal: list[MealImpactPointPayload]
    withoutMeal: list[MealImpactPointPayload]


class CartItemPayload(BaseModel):
    id: UUID
    name: str
    category: str | None = None
    quantity: str | None = None
    notes: str | None = None
    estimatedPrice: float | None = None
    isSelected: bool = True


class MealInsightResponse(BaseModel):
    mealLog: MealLogPayload
    mealImageName: str | None = None
    suggestionImageName: str | None = None
    feedback: MealFeedbackPayload
    spikeEvent: SpikeEventPayload | None = None
    impact: MealImpactChartPayload
    suggestedCartItems: list[CartItemPayload] = Field(default_factory=list)
