from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from uuid import uuid4

from app.schemas.meals import CartItemPayload

logger = logging.getLogger(__name__)

_MEAL_ANALYSIS_SYSTEM = """You are a diabetes nutrition coach. Given a meal, respond with JSON only — no prose.

Schema:
{
  "summary": "clean 3-6 word meal description",
  "coachMessage": "2-3 sentence personalized coaching message about this specific meal and how it may affect blood glucose",
  "suggestedSwap": "one specific food swap to reduce glucose spike",
  "nutrition": {
    "totals": {
      "carbohydrateGrams": 45,
      "addedSugarGrams": 5,
      "fiberGrams": 3,
      "proteinGrams": 20
    }
  },
  "cartItems": [
    {"name": "item name", "category": "Produce|Protein|Carbs|Dairy|Beverage|Snack", "quantity": "e.g. 1 lb"}
  ]
}

Estimate the nutrition totals for the full meal. Include 3-5 cart items that are healthier alternatives relevant to this meal."""

_WEEKLY_CART_SYSTEM = """You are a diabetes nutrition coach creating a personalized weekly grocery list.
Respond with JSON only — no prose.

Schema:
{
  "title": "Your weekly grocery list",
  "items": [
    {"name": "item name", "category": "Produce|Protein|Carbs|Dairy|Beverage|Snack", "quantity": "e.g. 1 lb", "reason": "one-sentence rationale"}
  ]
}

Include 12-15 items that help reduce glucose spikes based on the user's eating history."""


@dataclass
class MealAnalysisResult:
    summary: str
    suggested_swap: str
    cart_items: list[CartItemPayload] = field(default_factory=list)
    nutrition: dict | None = None
    coach_message: str | None = None


@dataclass
class WeeklyCartResult:
    title: str
    items: list[CartItemPayload] = field(default_factory=list)


class OpenAIClient:
    def __init__(self, api_key: str, model: str = "gpt-4o") -> None:
        self._client = None
        self._model = model
        if api_key:
            try:
                from openai import OpenAI
                self._client = OpenAI(api_key=api_key)
            except Exception:
                logger.warning("Failed to initialize OpenAI client.")

    # ------------------------------------------------------------------
    # Meal analysis
    # ------------------------------------------------------------------

    def analyze_meal_text(self, summary: str) -> MealAnalysisResult:
        if self._client is None:
            return self._fallback_analysis(summary)
        try:
            response = self._client.responses.create(
                model=self._model,
                instructions=_MEAL_ANALYSIS_SYSTEM,
                input=f"Meal: {summary}",
            )
            return self._parse_analysis(response.output_text, fallback_summary=summary)
        except Exception as exc:
            logger.warning("OpenAI text analysis failed: %s", exc)
            return self._fallback_analysis(summary)

    def analyze_meal_image(self, image_base64: str, mime_type: str = "image/jpeg") -> MealAnalysisResult:
        if self._client is None:
            return self._fallback_analysis("Photo meal")
        try:
            response = self._client.responses.create(
                model=self._model,
                instructions=_MEAL_ANALYSIS_SYSTEM,
                input=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "input_image",
                                "image_url": f"data:{mime_type};base64,{image_base64}",
                            },
                            {
                                "type": "input_text",
                                "text": "What meal is in this image?",
                            },
                        ],
                    }
                ],
            )
            return self._parse_analysis(response.output_text, fallback_summary="Photo meal")
        except Exception as exc:
            logger.warning("OpenAI image analysis failed: %s", exc)
            return self._fallback_analysis("Photo meal")

    # ------------------------------------------------------------------
    # Weekly cart
    # ------------------------------------------------------------------

    def generate_weekly_cart(
        self,
        meals: list[dict],
        spike_events: list[dict],
        care_goals: list[str],
        diet_preferences: list[str],
    ) -> WeeklyCartResult:
        if self._client is None:
            return WeeklyCartResult(title="Weekly grocery list", items=[])
        try:
            meal_lines = "\n".join(
                f"- {m.get('loggedAt', '')[:10]}: {m.get('summary', 'Unknown meal')}"
                for m in meals
            )
            spike_lines = "\n".join(
                f"- Delta {s.get('deltaMgdl', '?')} mg/dL after {s.get('mealSummary', 'a meal')}"
                for s in spike_events[:5]
            )
            user_context = (
                f"Care goals: {', '.join(care_goals) or 'Reduce spikes'}\n"
                f"Diet preferences: {', '.join(diet_preferences) or 'None specified'}"
            )
            prompt = (
                f"{user_context}\n\n"
                f"Meals this week:\n{meal_lines or 'No meals logged'}\n\n"
                f"Notable glucose events:\n{spike_lines or 'No significant spikes'}\n\n"
                "Generate a weekly grocery list focused on stabilizing blood glucose."
            )
            response = self._client.responses.create(
                model=self._model,
                instructions=_WEEKLY_CART_SYSTEM,
                input=prompt,
            )
            return self._parse_weekly_cart(response.output_text)
        except Exception as exc:
            logger.warning("OpenAI weekly cart failed: %s", exc)
            return WeeklyCartResult(title="Weekly grocery list", items=[])

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _parse_analysis(self, text: str, *, fallback_summary: str) -> MealAnalysisResult:
        try:
            start = text.find("{")
            end = text.rfind("}") + 1
            data = json.loads(text[start:end])
            items = [
                CartItemPayload(
                    id=uuid4(),
                    name=item["name"],
                    category=item.get("category"),
                    quantity=item.get("quantity"),
                    isSelected=True,
                )
                for item in data.get("cartItems", [])
            ]
            return MealAnalysisResult(
                summary=data.get("summary", fallback_summary),
                suggested_swap=data.get("suggestedSwap", "Try adding more vegetables"),
                cart_items=items,
                nutrition=data.get("nutrition"),
                coach_message=data.get("coachMessage"),
            )
        except Exception:
            return self._fallback_analysis(fallback_summary)

    def _parse_weekly_cart(self, text: str) -> WeeklyCartResult:
        try:
            start = text.find("{")
            end = text.rfind("}") + 1
            data = json.loads(text[start:end])
            items = [
                CartItemPayload(
                    id=uuid4(),
                    name=item["name"],
                    category=item.get("category"),
                    quantity=item.get("quantity"),
                    notes=item.get("reason"),
                    isSelected=True,
                )
                for item in data.get("items", [])
            ]
            return WeeklyCartResult(title=data.get("title", "Weekly grocery list"), items=items)
        except Exception:
            return WeeklyCartResult(title="Weekly grocery list", items=[])

    @staticmethod
    def _fallback_analysis(summary: str) -> MealAnalysisResult:
        from app.services.meal_service import MealService
        template = MealService._static_template_for(summary)
        return MealAnalysisResult(
            summary=summary,
            suggested_swap=template.suggested_swap,
            cart_items=template.cart_items,
        )
