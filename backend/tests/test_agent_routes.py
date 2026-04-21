from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi.testclient import TestClient

from app.persistence.glucose_store import StoredGlucoseReading
from app.persistence.user_store import StoredUser
from app.services.container import get_agent_service, get_glucose_store, get_cart_store, get_user_store


def _seed_spike(user_id: str) -> datetime:
    end = datetime.now(UTC).replace(second=0, microsecond=0)
    start = end - timedelta(minutes=105)
    values = [112, 116, 118, 124, 151, 187, 196, 184]
    readings = [
        StoredGlucoseReading(
            id=f"{user_id}:test:{index}",
            timestamp=start + timedelta(minutes=15 * index),
            value_mgdl=value,
            source="test",
            trend="flat",
        )
        for index, value in enumerate(values)
    ]
    get_glucose_store().upsert_readings(user_id, readings)
    return start + timedelta(minutes=60)


def test_agent_feed_prompts_for_missing_meal_log(client: TestClient) -> None:
    user = "agent-no-meal"
    _seed_spike(user)

    created = get_agent_service().process_recent_spikes(user)
    assert created == 1

    feed = client.get("/agent/feed", headers={"X-User-Id": user})
    assert feed.status_code == 200
    payload = feed.json()
    assert len(payload["runs"]) == 1
    assert payload["runs"][0]["kind"] == "spike_triggered"
    assert payload["runs"][0]["recommendationsCreated"] == 1
    assert payload["recommendations"][0]["notificationDraft"]["kind"] == "log_meal_prompt"
    assert payload["recommendations"][0]["actionLabel"] == "Log meal"


def test_agent_feed_uses_nearby_meal_when_available(client: TestClient) -> None:
    user = "agent-with-meal"
    meal_time = _seed_spike(user) - timedelta(minutes=30)
    meal_id = str(uuid4())
    payload = {
        "id": meal_id,
        "loggedAt": meal_time.isoformat().replace("+00:00", "Z"),
        "source": "text",
        "summary": "Greek yogurt with berries",
        "rawInput": "Greek yogurt with berries",
        "notes": None,
        "assets": [],
        "analysis": {
            "nutrition": {
                "totals": {
                    "calories": 240,
                    "proteinGrams": 22,
                    "carbohydrateGrams": 24,
                    "fatGrams": 6,
                    "fiberGrams": 5,
                    "addedSugarGrams": 8,
                },
                "items": [],
            },
            "suggestedSwap": "Swap sweetened yogurt for plain Greek yogurt",
        },
    }
    created = client.post("/meals", headers={"X-User-Id": user}, json=payload)
    assert created.status_code == 200

    generated = get_agent_service().process_recent_spikes(user)
    assert generated == 1

    feed = client.get("/agent/feed", headers={"X-User-Id": user})
    assert feed.status_code == 200
    recommendation = feed.json()["recommendations"][0]
    assert recommendation["relatedMealLogID"] == meal_id
    assert recommendation["notificationDraft"]["kind"] == "meal_feedback_ready"
    assert recommendation["actionLabel"] == "View feedback"


def test_agent_run_deduplicates_same_spike(client: TestClient) -> None:
    user = "agent-dedup"
    _seed_spike(user)

    first = get_agent_service().process_recent_spikes(user)
    second = get_agent_service().process_recent_spikes(user)

    assert first == 1
    assert second == 0

    feed = client.get("/agent/feed", headers={"X-User-Id": user})
    assert feed.status_code == 200
    assert len(feed.json()["runs"]) == 1


def test_agent_recommendation_read_and_dismiss_persist(client: TestClient) -> None:
    user = "agent-state"
    _seed_spike(user)
    assert get_agent_service().process_recent_spikes(user) == 1

    initial_feed = client.get("/agent/feed", headers={"X-User-Id": user})
    recommendation_id = initial_feed.json()["recommendations"][0]["id"]

    read_response = client.post(f"/agent/recommendations/{recommendation_id}/read", headers={"X-User-Id": user})
    assert read_response.status_code == 200
    assert read_response.json()["readAt"] is not None
    assert read_response.json()["dismissedAt"] is None

    dismiss_response = client.post(f"/agent/recommendations/{recommendation_id}/dismiss", headers={"X-User-Id": user})
    assert dismiss_response.status_code == 200
    assert dismiss_response.json()["readAt"] is not None
    assert dismiss_response.json()["dismissedAt"] is not None

    final_feed = client.get("/agent/feed", headers={"X-User-Id": user})
    final_recommendation = final_feed.json()["recommendations"][0]
    assert final_recommendation["readAt"] is not None
    assert final_recommendation["dismissedAt"] is not None


def test_daily_summary_creates_recommendation_for_notable_day(client: TestClient) -> None:
    user = "agent-daily-notable"
    day = datetime.now(UTC).date() - timedelta(days=1)
    start = datetime.combine(day, datetime.min.time(), tzinfo=UTC) + timedelta(hours=8)
    values = [118, 122, 128, 141, 188, 194, 176, 165, 172, 184, 190, 178]
    readings = [
        StoredGlucoseReading(
            id=f"{user}:daily:{index}",
            timestamp=start + timedelta(hours=index),
            value_mgdl=value,
            source="test",
            trend="flat",
        )
        for index, value in enumerate(values)
    ]
    get_glucose_store().upsert_readings(user, readings)

    created = get_agent_service().process_daily_summary(user, target_date=day)
    assert created == 1

    feed = client.get("/agent/feed", headers={"X-User-Id": user})
    assert feed.status_code == 200
    payload = feed.json()
    assert payload["runs"][0]["kind"] == "daily_summary"
    assert payload["runs"][0]["status"] == "completed"
    assert payload["recommendations"][0]["runKind"] == "daily_summary"
    assert payload["recommendations"][0]["notificationDraft"]["kind"] == "daily_summary_ready"


def test_daily_summary_skips_stable_day(client: TestClient) -> None:
    user = "agent-daily-stable"
    day = datetime.now(UTC).date() - timedelta(days=1)
    start = datetime.combine(day, datetime.min.time(), tzinfo=UTC) + timedelta(hours=8)
    values = [112, 118, 121, 119, 123, 125, 120, 117]
    readings = [
        StoredGlucoseReading(
            id=f"{user}:stable:{index}",
            timestamp=start + timedelta(hours=index),
            value_mgdl=value,
            source="test",
            trend="flat",
        )
        for index, value in enumerate(values)
    ]
    get_glucose_store().upsert_readings(user, readings)

    created = get_agent_service().process_daily_summary(user, target_date=day)
    assert created == 0

    feed = client.get("/agent/feed", headers={"X-User-Id": user})
    assert feed.status_code == 200
    payload = feed.json()
    assert payload["runs"][0]["kind"] == "daily_summary"
    assert payload["runs"][0]["status"] == "skipped"
    assert payload["recommendations"] == []


def test_weekly_summary_creates_recommendation_and_cart(client: TestClient) -> None:
    user = "agent-weekly"
    get_user_store().create_user(
        StoredUser(
            id=user,
            display_name="Weekly User",
            diet_preferences=["Low sodium"],
            care_goals=["Keep glucose steady"],
            support_preferences=["Weekly check-ins"],
            created_at=datetime.now(UTC),
        )
    )

    day = datetime.now(UTC).date() - timedelta(days=1)
    start = datetime.combine(day, datetime.min.time(), tzinfo=UTC) + timedelta(hours=8)
    values = [118, 122, 128, 141, 188, 194, 176, 165, 172, 184, 190, 178]
    readings = [
        StoredGlucoseReading(
            id=f"{user}:weekly:{index}",
            timestamp=start + timedelta(hours=index),
            value_mgdl=value,
            source="test",
            trend="flat",
        )
        for index, value in enumerate(values)
    ]
    get_glucose_store().upsert_readings(user, readings)

    meal_payload = {
        "id": str(uuid4()),
        "loggedAt": (start + timedelta(hours=4)).isoformat().replace("+00:00", "Z"),
        "source": "text",
        "summary": "Turkey sandwich and chips",
        "rawInput": "Turkey sandwich and chips",
        "notes": None,
        "assets": [],
        "analysis": {
            "nutrition": {
                "totals": {
                    "calories": 520,
                    "proteinGrams": 24,
                    "carbohydrateGrams": 48,
                    "fatGrams": 16,
                    "fiberGrams": 4,
                    "addedSugarGrams": 2,
                },
                "items": [],
            },
        },
    }
    created = client.post("/meals", headers={"X-User-Id": user}, json=meal_payload)
    assert created.status_code == 200
    assert get_agent_service().process_daily_summary(user, target_date=day) == 1

    weekly_created = get_agent_service().process_weekly_summary(user, anchor_date=datetime.now(UTC).date())
    assert weekly_created == 1

    feed = client.get("/agent/feed", headers={"X-User-Id": user})
    assert feed.status_code == 200
    weekly = next(item for item in feed.json()["recommendations"] if item["runKind"] == "weekly_planning")
    assert weekly["notificationDraft"]["kind"] == "weekly_plan_ready"
    assert weekly["actionLabel"] == "Open cart"

    latest_cart = get_cart_store().fetch_latest_draft(user_id=user)
    assert latest_cart is not None
    assert latest_cart.payload["source"] == "weeklyCart"
