from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from app.api.errors import AppError
from app.persistence.glucose_store import SQLiteGlucoseStore
from app.persistence.meal_store import SQLiteMealStore, StoredMealLog
from app.schemas.meals import (
    CartItemPayload,
    MealFeedbackPayload,
    MealImpactChartPayload,
    MealImpactPointPayload,
    MealInsightResponse,
    MealLogPayload,
    RecentMealsResponse,
    SpikeEventPayload,
    SpikeMetricsPayload,
)
from app.clients.openai_client import OpenAIClient
from app.services.cgm_service import CGMService
from app.services.dexcom_service import DexcomService


@dataclass
class MealTemplate:
    meal_image_name: str | None
    suggestion_image_name: str | None
    suggested_swap: str
    cart_items: list[CartItemPayload]
    coach_message: str | None = None


class MealService:
    def __init__(
        self,
        meal_store: SQLiteMealStore,
        glucose_store: SQLiteGlucoseStore,
        cgm_service: CGMService,
        dexcom_service: DexcomService,
        claude_client: OpenAIClient | None = None,
    ) -> None:
        self.meal_store = meal_store
        self.glucose_store = glucose_store
        self.cgm_service = cgm_service
        self.dexcom_service = dexcom_service
        self.claude_client = claude_client

    def create_meal(self, user_id: str, meal: MealLogPayload) -> MealLogPayload:
        updates: dict = {}
        if self.claude_client and meal.analysis is None:
            result = self.claude_client.analyze_meal_text(meal.summary)
            analysis: dict = {"suggestedSwap": result.suggested_swap}
            if result.nutrition:
                analysis["nutrition"] = result.nutrition
            if result.serving_size:
                analysis["servingSize"] = result.serving_size
            updates["analysis"] = analysis
            # Only fill serving size from AI if the user didn't provide one
            if result.serving_size and not meal.servingSize:
                updates["servingSize"] = result.serving_size
        if updates:
            meal = meal.model_copy(update=updates)
        self.meal_store.upsert_meal(
            user_id=user_id,
            meal=StoredMealLog(
                id=str(meal.id),
                logged_at=meal.loggedAt,
                source=meal.source,
                summary=meal.summary,
                payload=meal.model_dump(mode="json"),
            ),
        )
        return meal

    def fetch_recent_meals(self, user_id: str, limit: int) -> RecentMealsResponse:
        meals = [
            MealLogPayload.model_validate(stored.payload)
            for stored in self.meal_store.fetch_recent_meals(user_id=user_id, limit=limit)
        ]
        return RecentMealsResponse(meals=meals)

    def fetch_meal_insight(self, user_id: str, meal_id: UUID) -> MealInsightResponse:
        stored_meal = self.meal_store.fetch_meal(user_id=user_id, meal_id=meal_id)
        if stored_meal is None:
            raise AppError(code="meal_not_found", message="Meal log not found", status_code=404)

        meal = MealLogPayload.model_validate(stored_meal.payload)
        self._maybe_sync_recent_glucose(user_id=user_id)

        readings = self.cgm_service.fetch_readings(
            user_id=user_id,
            start=meal.loggedAt - timedelta(minutes=30),
            end=meal.loggedAt + timedelta(hours=2),
        ).readings
        template = self._template_for(meal)

        insight = self._build_meal_insight(meal=meal, readings=readings, template=template)

        self.meal_store.upsert_feedback(
            user_id=user_id,
            meal_log_id=meal.id,
            created_at=insight.feedback.createdAt,
            payload=insight.feedback.model_dump(mode="json"),
        )
        if insight.spikeEvent is not None:
            self.meal_store.upsert_spike_event(
                user_id=user_id,
                meal_log_id=meal.id,
                created_at=insight.spikeEvent.createdAt,
                payload=insight.spikeEvent.model_dump(mode="json"),
            )
        return insight

    def _maybe_sync_recent_glucose(self, user_id: str) -> None:
        record = self.dexcom_service.get_record(user_id)
        if record.status == "connected":
            self.cgm_service.sync_recent_glucose(user_id)

    def _build_meal_insight(
        self,
        *,
        meal: MealLogPayload,
        readings: list[Any],
        template: MealTemplate,
    ) -> MealInsightResponse:
        measured = self._measured_insight(meal=meal, readings=readings, template=template)
        if measured is not None:
            return measured
        return self._predicted_insight(meal=meal, readings=readings, template=template)

    def _measured_insight(
        self,
        *,
        meal: MealLogPayload,
        readings: list[Any],
        template: MealTemplate,
    ) -> MealInsightResponse | None:
        baseline_readings = [reading for reading in readings if reading.timestamp < meal.loggedAt][-3:]
        post_meal_readings = [reading for reading in readings if reading.timestamp >= meal.loggedAt]
        if len(baseline_readings) < 2 or len(post_meal_readings) < 4:
            return None

        baseline = sum(reading.valueMgdl for reading in baseline_readings) / len(baseline_readings)
        peak_reading = max(post_meal_readings, key=lambda reading: reading.valueMgdl)
        peak = float(peak_reading.valueMgdl)
        delta = max(peak - baseline, 0)
        peak_minutes = max(int((peak_reading.timestamp - meal.loggedAt).total_seconds() / 60), 0)
        return_reading = next(
            (
                reading
                for reading in post_meal_readings
                if reading.timestamp > peak_reading.timestamp and reading.valueMgdl <= min(180, baseline + 8)
            ),
            None,
        )
        return_minutes = (
            max(int((return_reading.timestamp - meal.loggedAt).total_seconds() / 60), 0)
            if return_reading is not None
            else None
        )
        confidence = min(0.95, 0.45 + (len(post_meal_readings) / 20) + min(delta, 50) / 100)

        spike_id = uuid4()
        spike = SpikeEventPayload(
            id=spike_id,
            mealLogID=meal.id,
            createdAt=datetime.now(UTC),
            eventKind="measured",
            status="open",
            startedAt=meal.loggedAt,
            peakAt=peak_reading.timestamp,
            resolvedAt=return_reading.timestamp if return_reading else None,
            confidence=confidence,
            metrics=SpikeMetricsPayload(
                baselineMgdl=baseline,
                peakMgdl=peak,
                deltaMgdl=delta,
                timeToPeakMinutes=peak_minutes,
                returnToRangeMinutes=return_minutes,
            ),
            notes=self._measured_notes(delta=delta, baseline=baseline),
        )

        feedback = MealFeedbackPayload(
            id=uuid4(),
            mealLogID=meal.id,
            createdAt=datetime.now(UTC),
            mode="measured",
            headline="Feedback on your meal",
            summary=self._measured_summary(delta),
            coachMessage=template.coach_message or self._measured_coach_message(delta),
            suggestedSwap=template.suggested_swap,
            linkedSpikeEventID=spike_id,
            suggestedCartItems=[item.name for item in template.cart_items],
        )

        impact = MealImpactChartPayload(
            withMeal=[
                MealImpactPointPayload(
                    minute=max((reading.timestamp - meal.loggedAt).total_seconds() / 60, 0),
                    glucose=float(reading.valueMgdl),
                )
                for reading in post_meal_readings
            ],
            withoutMeal=self._baseline_series(baseline),
        )

        return MealInsightResponse(
            mealLog=meal,
            mealImageName=template.meal_image_name,
            suggestionImageName=template.suggestion_image_name,
            feedback=feedback,
            spikeEvent=spike,
            impact=impact,
            suggestedCartItems=template.cart_items,
        )

    def _predicted_insight(
        self,
        *,
        meal: MealLogPayload,
        readings: list[Any],
        template: MealTemplate,
    ) -> MealInsightResponse:
        baseline = float(readings[-1].valueMgdl) if readings else 118.0
        totals = ((meal.analysis or {}).get("nutrition") or {}).get("totals", {})

        carbs = float(totals.get("carbohydrateGrams") or 45)
        added_sugar = float(totals.get("addedSugarGrams") or 0)
        fiber = float(totals.get("fiberGrams") or 0)
        protein = float(totals.get("proteinGrams") or 0)

        delta = 16.0
        delta += min(max((carbs - 35) * 0.45, 0), 18)
        delta += min(max(added_sugar * 0.7, 0), 12)
        delta -= min(max(fiber * 0.8, 0), 8)
        delta -= min(max((protein - 20) * 0.18, 0), 5)
        delta += self._keyword_adjustment(meal.summary)
        delta = min(max(delta, 10), 48)

        peak = baseline + delta
        time_to_peak = 36 if delta > 28 else 42

        spike_id = uuid4()
        spike = SpikeEventPayload(
            id=spike_id,
            mealLogID=meal.id,
            createdAt=datetime.now(UTC),
            eventKind="predicted",
            status="open",
            startedAt=meal.loggedAt,
            confidence=0.64,
            metrics=SpikeMetricsPayload(
                baselineMgdl=baseline,
                peakMgdl=peak,
                deltaMgdl=delta,
                timeToPeakMinutes=time_to_peak,
                returnToRangeMinutes=115,
            ),
            notes=self._predicted_notes(delta),
        )

        feedback = MealFeedbackPayload(
            id=uuid4(),
            mealLogID=meal.id,
            createdAt=datetime.now(UTC),
            mode="predicted",
            headline="Feedback on your meal",
            summary=self._predicted_summary(delta),
            coachMessage=template.coach_message or self._predicted_coach_message(delta),
            suggestedSwap=template.suggested_swap,
            linkedSpikeEventID=spike_id,
            suggestedCartItems=[item.name for item in template.cart_items],
        )

        return MealInsightResponse(
            mealLog=meal,
            mealImageName=template.meal_image_name,
            suggestionImageName=template.suggestion_image_name,
            feedback=feedback,
            spikeEvent=spike,
            impact=MealImpactChartPayload(
                withMeal=self._predicted_series(baseline, peak),
                withoutMeal=self._baseline_series(baseline),
            ),
            suggestedCartItems=template.cart_items,
        )

    def analyze_photo(self, image_base64: str, mime_type: str) -> tuple[str, str | None]:
        """Returns (summary, serving_size)."""
        if self.claude_client:
            result = self.claude_client.analyze_meal_image(image_base64, mime_type)
            return result.summary, result.serving_size
        return "Photo meal", None

    def lookup_barcode(self, code: str) -> str:
        try:
            import httpx
            url = f"https://world.openfoodfacts.org/api/v2/product/{code}.json"
            response = httpx.get(url, timeout=6.0)
            response.raise_for_status()
            product = response.json().get("product", {})
            name = product.get("product_name") or product.get("generic_name") or ""
            brand = product.get("brands") or ""
            serving = product.get("serving_size") or ""
            parts = [p for p in [brand, name, serving] if p]
            return ", ".join(parts) if parts else "Scanned product"
        except Exception:
            return "Scanned product"

    def _template_for(self, meal: MealLogPayload) -> MealTemplate:
        if self.claude_client:
            result = self.claude_client.analyze_meal_text(meal.summary)
            return MealTemplate(
                meal_image_name=self._meal_image_name(meal),
                suggestion_image_name="chickenandsalad",
                suggested_swap=result.suggested_swap,
                cart_items=result.cart_items,
                coach_message=result.coach_message,
            )
        return self._static_template_for(meal.summary)

    @classmethod
    def _static_template_for(cls, summary: str) -> MealTemplate:
        summary_lower = summary.lower()
        image_name = cls._static_meal_image_name(summary_lower)
        if "soda" in summary_lower:
            return MealTemplate(
                meal_image_name=image_name,
                suggestion_image_name="chickenandsalad",
                suggested_swap="Swap soda for water",
                cart_items=[
                    cls._cart_item("Sparkling water", "Beverage", "1 pack"),
                    cls._cart_item("Chicken breast", "Protein", "1.5 lb"),
                    cls._cart_item("Mixed greens", "Produce", "1 box"),
                    cls._cart_item("Cherry tomatoes", "Produce", "1 pint"),
                    cls._cart_item("Whole-grain bread", "Carbs", "1 loaf"),
                ],
            )
        return MealTemplate(
            meal_image_name=image_name,
            suggestion_image_name="chickenandsalad" if image_name == "chickenandfries" else image_name,
            suggested_swap="Swap fries for a side salad",
            cart_items=[
                cls._cart_item("Mixed greens", "Produce", "1 box"),
                cls._cart_item("Cherry tomatoes", "Produce", "1 pint"),
                cls._cart_item("Cucumbers", "Produce", "2 ct"),
                cls._cart_item("Chicken breast", "Protein", "1.5 lb"),
                cls._cart_item("Whole-grain bread", "Carbs", "1 loaf"),
            ],
        )

    @staticmethod
    def _static_meal_image_name(summary_lower: str) -> str | None:
        if "fries" in summary_lower or "burger" in summary_lower:
            return "chickenandfries"
        if "salad" in summary_lower:
            return "chickenandsalad"
        return None

    def _meal_image_name(self, meal: MealLogPayload) -> str | None:
        for asset in meal.assets:
            local_identifier = asset.get("localIdentifier")
            if isinstance(local_identifier, str) and local_identifier:
                return local_identifier

        summary = meal.summary.lower()
        if "fries" in summary or "burger" in summary:
            return "chickenandfries"
        if "salad" in summary:
            return "chickenandsalad"
        return None

    @staticmethod
    def _cart_item(name: str, category: str, quantity: str) -> CartItemPayload:
        return CartItemPayload(id=uuid4(), name=name, category=category, quantity=quantity, isSelected=True)

    @staticmethod
    def _baseline_series(baseline: float) -> list[MealImpactPointPayload]:
        return [
            MealImpactPointPayload(minute=0, glucose=baseline),
            MealImpactPointPayload(minute=30, glucose=baseline - 1.2),
            MealImpactPointPayload(minute=60, glucose=baseline - 2.2),
            MealImpactPointPayload(minute=90, glucose=baseline - 3.1),
            MealImpactPointPayload(minute=120, glucose=baseline - 4.0),
        ]

    @staticmethod
    def _predicted_series(baseline: float, peak: float) -> list[MealImpactPointPayload]:
        return [
            MealImpactPointPayload(minute=0, glucose=baseline),
            MealImpactPointPayload(minute=15, glucose=baseline + (peak - baseline) * 0.38),
            MealImpactPointPayload(minute=32, glucose=peak - 1.5),
            MealImpactPointPayload(minute=48, glucose=peak),
            MealImpactPointPayload(minute=68, glucose=baseline + (peak - baseline) * 0.62),
            MealImpactPointPayload(minute=92, glucose=baseline + (peak - baseline) * 0.34),
            MealImpactPointPayload(minute=120, glucose=baseline + (peak - baseline) * 0.12),
        ]

    @staticmethod
    def _measured_summary(delta: float) -> str:
        if delta < 15:
            return "Your CGM stayed fairly steady after this meal"
        if delta < 30:
            return "Your CGM showed a moderate rise, then a steady cooldown"
        return "Your CGM showed a sharper rise after this meal"

    @staticmethod
    def _measured_coach_message(delta: float) -> str:
        if delta < 15:
            return "This meal stayed relatively steady on your CGM. Keeping the protein and swapping in a little more produce can help you stay in range."
        if delta < 30:
            return "This meal caused a moderate glucose rise. A simpler carb swap can make the rise gentler next time."
        return "This meal pushed your glucose up more than ideal. A lighter starch choice would likely make the next rise much easier to manage."

    @staticmethod
    def _predicted_summary(delta: float) -> str:
        if delta < 18:
            return "You may see a small rise, then a steady decrease"
        if delta < 32:
            return "You may see a short rise, followed by a steady decrease"
        return "You may see a stronger rise before your glucose cools down"

    @staticmethod
    def _predicted_coach_message(delta: float) -> str:
        if delta < 18:
            return "This meal looks fairly balanced. Keeping the protein and vegetables in place should help keep the rise modest."
        if delta < 32:
            return "This meal is nicely balanced. You may see a short rise in your blood sugar, followed by a steady decrease."
        return "This meal may raise your blood sugar more than ideal. One simple food swap could make the rise gentler next time."

    @staticmethod
    def _measured_notes(*, delta: float, baseline: float) -> list[str]:
        return [
            "Spike rose above the usual target range." if delta >= 30 else "Glucose stayed closer to the target range.",
            f"Baseline was about {int(round(baseline))} mg/dL before the meal.",
        ]

    @staticmethod
    def _predicted_notes(delta: float) -> list[str]:
        return [
            "Estimate based on recent glucose level and meal composition.",
            "Higher-carb items likely drive most of the rise." if delta >= 30 else "Protein and fiber should help soften the rise.",
        ]

    @staticmethod
    def _keyword_adjustment(summary: str) -> float:
        normalized = summary.lower()
        adjustment = 0.0
        if "fries" in normalized:
            adjustment += 7
        if "soda" in normalized:
            adjustment += 10
        if "rice" in normalized:
            adjustment += 8
        if "burger" in normalized:
            adjustment += 6
        if "salad" in normalized:
            adjustment -= 6
        if "grilled" in normalized:
            adjustment -= 3
        return adjustment
