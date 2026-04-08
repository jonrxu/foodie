from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi.testclient import TestClient


def _meal_payload(*, logged_at: datetime, summary: str = "Chicken and fries") -> dict:
    return {
        "id": str(uuid4()),
        "loggedAt": logged_at.isoformat().replace("+00:00", "Z"),
        "source": "photo",
        "summary": summary,
        "rawInput": "Captured meal photo",
        "notes": None,
        "assets": [
            {
                "id": str(uuid4()),
                "kind": "photo",
                "localIdentifier": "chickenandfries",
                "mimeType": "image/jpeg",
                "createdAt": logged_at.isoformat().replace("+00:00", "Z"),
                "previewText": summary,
            }
        ],
        "analysis": {
            "mealType": "lunch",
            "estimatedCalories": 640,
            "confidence": 0.9,
            "nutrition": {
                "totals": {
                    "calories": 640,
                    "proteinGrams": 35,
                    "carbohydrateGrams": 54,
                    "fatGrams": 24,
                    "fiberGrams": 4,
                    "addedSugarGrams": 3,
                },
                "items": [],
            },
            "healthIndex": 71,
            "healthLevel": "Balanced",
            "healthTags": ["Protein", "Carbs"],
            "highlights": ["Protein helps steady the rise"],
        },
    }


def _connect_and_sync(client: TestClient, user: str) -> None:
    start = client.post("/dexcom/connect/start", headers={"X-User-Id": user})
    state = start.json()["authorization_url"].split("state=")[1].split("&")[0]
    callback = client.get(f"/dexcom/connect/callback?state={state}&code=fake-auth-code", follow_redirects=False)
    assert callback.status_code == 302
    sync = client.post("/dexcom/sync", headers={"X-User-Id": user})
    assert sync.status_code == 200


def test_create_meal_and_fetch_recent(client: TestClient) -> None:
    user = "meal-user"
    payload = _meal_payload(logged_at=datetime.now(UTC) - timedelta(hours=2))

    created = client.post("/meals", headers={"X-User-Id": user}, json=payload)
    assert created.status_code == 200
    assert created.json()["summary"] == "Chicken and fries"

    recent = client.get("/meals/recent", headers={"X-User-Id": user})
    assert recent.status_code == 200
    meals = recent.json()["meals"]
    assert len(meals) == 1
    assert meals[0]["id"] == payload["id"]


def test_meal_feedback_returns_measured_insight_when_cgm_data_exists(client: TestClient) -> None:
    user = "meal-cgm-user"
    _connect_and_sync(client, user)

    payload = _meal_payload(logged_at=datetime.now(UTC) - timedelta(hours=2))
    created = client.post("/meals", headers={"X-User-Id": user}, json=payload)
    assert created.status_code == 200

    feedback = client.get(f"/meals/{payload['id']}/feedback", headers={"X-User-Id": user})
    assert feedback.status_code == 200
    insight = feedback.json()
    assert insight["feedback"]["mode"] == "measured"
    assert insight["spikeEvent"]["eventKind"] == "measured"
    assert len(insight["impact"]["withMeal"]) > 0
    assert len(insight["suggestedCartItems"]) > 0


def test_meal_feedback_returns_predicted_without_cgm_connection(client: TestClient) -> None:
    user = "meal-predicted-user"
    payload = _meal_payload(
        logged_at=datetime.now(UTC) - timedelta(hours=2),
        summary="Burger, fries, and soda",
    )
    created = client.post("/meals", headers={"X-User-Id": user}, json=payload)
    assert created.status_code == 200

    feedback = client.get(f"/meals/{payload['id']}/feedback", headers={"X-User-Id": user})
    assert feedback.status_code == 200
    insight = feedback.json()
    assert insight["feedback"]["mode"] == "predicted"
    assert insight["feedback"]["suggestedSwap"] == "Swap soda for water"
    assert insight["spikeEvent"]["eventKind"] == "predicted"


def test_meal_feedback_missing_meal_returns_404(client: TestClient) -> None:
    response = client.get(f"/meals/{uuid4()}/feedback", headers={"X-User-Id": "missing-user"})
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "meal_not_found"
