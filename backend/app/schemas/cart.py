from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.meals import CartItemPayload


class CartDraftPayload(BaseModel):
    id: UUID
    title: str
    source: str
    storeName: str | None = None
    createdAt: datetime
    updatedAt: datetime
    totalEstimate: float | None = None
    checkoutURL: str | None = None
    items: list[CartItemPayload] = Field(default_factory=list)


class CartGenerationRequest(BaseModel):
    mealLogID: UUID | None = None


class CartCheckoutRequest(BaseModel):
    draftID: UUID | None = None


class CartDraftEnvelope(BaseModel):
    draft: CartDraftPayload | None = None
