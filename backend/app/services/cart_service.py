from __future__ import annotations

from datetime import UTC, datetime
from typing import Iterable
from urllib.parse import urlencode
from uuid import UUID, uuid4

from app.api.errors import AppError
from app.config.settings import Settings
from app.persistence.cart_store import SQLiteCartStore, StoredCartDraft
from app.persistence.meal_store import SQLiteMealStore
from app.schemas.cart import CartCheckoutRequest, CartDraftEnvelope, CartDraftPayload, CartGenerationRequest
from app.schemas.meals import CartItemPayload, MealInsightResponse
from app.services.meal_service import MealService


class CartService:
    def __init__(
        self,
        settings: Settings,
        cart_store: SQLiteCartStore,
        meal_store: SQLiteMealStore,
        meal_service: MealService,
    ) -> None:
        self.settings = settings
        self.cart_store = cart_store
        self.meal_store = meal_store
        self.meal_service = meal_service
        self.price_lookup = {
            "mixed greens": 4.29,
            "cherry tomatoes": 3.49,
            "cucumbers": 1.79,
            "chicken breast": 8.99,
            "whole-grain bread": 4.49,
            "sparkling water": 5.99,
        }
        self.category_price_lookup = {
            "produce": 3.29,
            "protein": 7.49,
            "carbs": 4.19,
            "beverage": 5.49,
        }

    def generate_cart(self, user_id: str, request: CartGenerationRequest) -> CartDraftEnvelope:
        meal_id = request.mealLogID or self._latest_meal_id(user_id)
        if meal_id is None:
            raise AppError(
                code="cart_source_missing",
                message="Log a meal before adding ingredients to your cart.",
                status_code=404,
            )

        insight = self.meal_service.fetch_meal_insight(user_id=user_id, meal_id=meal_id)
        existing_draft = self.cart_store.fetch_latest_draft(user_id=user_id)
        draft = self._build_draft(insight=insight, existing=existing_draft)
        self.cart_store.upsert_draft(
            user_id=user_id,
            draft=StoredCartDraft(
                id=str(draft.id),
                source=draft.source,
                created_at=draft.createdAt,
                updated_at=draft.updatedAt,
                payload=draft.model_dump(mode="json"),
            ),
        )
        return CartDraftEnvelope(draft=draft)

    def prepare_checkout(self, user_id: str, request: CartCheckoutRequest) -> CartDraftEnvelope:
        stored = None
        if request.draftID is not None:
            stored = self.cart_store.fetch_draft(user_id=user_id, draft_id=request.draftID)
        else:
            stored = self.cart_store.fetch_latest_draft(user_id=user_id)

        if stored is None:
            raise AppError(
                code="cart_not_found",
                message="Generate a cart before starting checkout.",
                status_code=404,
            )

        draft = CartDraftPayload.model_validate(stored.payload)
        checkout_url = self._build_checkout_url(user_id=user_id, draft=draft)
        updated_draft = CartDraftPayload(
            id=draft.id,
            title=draft.title,
            source=draft.source,
            storeName=draft.storeName,
            createdAt=draft.createdAt,
            updatedAt=datetime.now(UTC),
            totalEstimate=draft.totalEstimate,
            checkoutURL=checkout_url,
            items=draft.items,
        )
        self.cart_store.upsert_draft(
            user_id=user_id,
            draft=StoredCartDraft(
                id=str(updated_draft.id),
                source=updated_draft.source,
                created_at=updated_draft.createdAt,
                updated_at=updated_draft.updatedAt,
                payload=updated_draft.model_dump(mode="json"),
            ),
        )
        return CartDraftEnvelope(draft=updated_draft)

    def fetch_latest_cart(self, user_id: str) -> CartDraftEnvelope:
        stored = self.cart_store.fetch_latest_draft(user_id=user_id)
        if stored is None:
            return CartDraftEnvelope(draft=None)
        return CartDraftEnvelope(draft=CartDraftPayload.model_validate(stored.payload))

    def _latest_meal_id(self, user_id: str) -> UUID | None:
        recent = self.meal_store.fetch_recent_meals(user_id=user_id, limit=1)
        if not recent:
            return None
        return UUID(recent[0].id)

    def _build_draft(
        self,
        *,
        insight: MealInsightResponse,
        existing: StoredCartDraft | None,
    ) -> CartDraftPayload:
        now = datetime.now(UTC)
        existing_payload = CartDraftPayload.model_validate(existing.payload) if existing is not None else None
        suggested_items = [self._with_price(item) for item in insight.suggestedCartItems]
        merged_items = self._merge_items(existing_payload.items if existing_payload is not None else [], suggested_items)
        total_estimate = round(sum(item.estimatedPrice or 0 for item in merged_items if item.isSelected), 2)

        return CartDraftPayload(
            id=existing_payload.id if existing_payload is not None else uuid4(),
            title=existing_payload.title if existing_payload is not None else "Recommended grocery swaps",
            source="mealFeedback",
            storeName=existing_payload.storeName if existing_payload is not None else "GIANT",
            createdAt=existing_payload.createdAt if existing_payload is not None else now,
            updatedAt=now,
            totalEstimate=total_estimate,
            checkoutURL=None,
            items=merged_items,
        )

    def _merge_items(
        self,
        existing_items: Iterable[CartItemPayload],
        suggested_items: Iterable[CartItemPayload],
    ) -> list[CartItemPayload]:
        merged: list[CartItemPayload] = []
        index_by_name: dict[str, int] = {}

        for item in list(existing_items) + list(suggested_items):
            key = self._normalize_name(item.name)
            if key in index_by_name:
                idx = index_by_name[key]
                current = merged[idx]
                merged[idx] = CartItemPayload(
                    id=current.id,
                    name=current.name,
                    category=current.category or item.category,
                    quantity=current.quantity or item.quantity,
                    notes=current.notes or item.notes,
                    estimatedPrice=current.estimatedPrice if current.estimatedPrice is not None else item.estimatedPrice,
                    isSelected=current.isSelected,
                )
            else:
                index_by_name[key] = len(merged)
                merged.append(item)

        return merged

    def _with_price(self, item: CartItemPayload) -> CartItemPayload:
        if item.estimatedPrice is not None:
            return item

        category_key = (item.category or "").strip().lower()
        estimated_price = self.price_lookup.get(self._normalize_name(item.name))
        if estimated_price is None:
            estimated_price = self.category_price_lookup.get(category_key, 3.99)

        return CartItemPayload(
            id=item.id,
            name=item.name,
            category=item.category,
            quantity=item.quantity,
            notes=item.notes,
            estimatedPrice=estimated_price,
            isSelected=item.isSelected,
        )

    @staticmethod
    def _normalize_name(name: str) -> str:
        return " ".join(name.lower().split())

    def _build_checkout_url(self, *, user_id: str, draft: CartDraftPayload) -> str:
        query = urlencode(
            {
                "foodie_cart_id": str(draft.id),
                "foodie_user_id": user_id,
                "store": draft.storeName or "GIANT",
                "estimated_total": f"{draft.totalEstimate or 0:.2f}",
            }
        )
        return f"{self.settings.instacart_handoff_base}?{query}"
