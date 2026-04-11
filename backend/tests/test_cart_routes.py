from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi.testclient import TestClient

from tests.test_meal_routes import _meal_payload


def test_generate_cart_from_latest_meal(client: TestClient) -> None:
    user = "cart-user"
    meal_payload = _meal_payload(logged_at=datetime.now(UTC) - timedelta(hours=1, minutes=50))
    created = client.post("/meals", headers={"X-User-Id": user}, json=meal_payload)
    assert created.status_code == 200

    generated = client.post("/cart/generate", headers={"X-User-Id": user}, json={})
    assert generated.status_code == 200
    draft = generated.json()["draft"]
    assert draft["source"] == "mealFeedback"
    assert draft["storeName"] == "GIANT"
    assert draft["totalEstimate"] > 0
    assert len(draft["items"]) >= 3


def test_generate_cart_for_specific_meal_and_fetch_latest(client: TestClient) -> None:
    user = "specific-cart-user"
    older_meal = _meal_payload(logged_at=datetime.now(UTC) - timedelta(hours=5), summary="Chicken and fries")
    newer_meal = _meal_payload(logged_at=datetime.now(UTC) - timedelta(hours=2), summary="Burger, fries, and soda")
    assert client.post("/meals", headers={"X-User-Id": user}, json=older_meal).status_code == 200
    assert client.post("/meals", headers={"X-User-Id": user}, json=newer_meal).status_code == 200

    generated = client.post(
        "/cart/generate",
        headers={"X-User-Id": user},
        json={"mealLogID": older_meal["id"]},
    )
    assert generated.status_code == 200
    first_names = {item["name"] for item in generated.json()["draft"]["items"]}
    assert "Mixed greens" in first_names

    latest = client.get("/cart/latest", headers={"X-User-Id": user})
    assert latest.status_code == 200
    assert latest.json()["draft"]["id"] == generated.json()["draft"]["id"]


def test_prepare_checkout_adds_handoff_url(client: TestClient) -> None:
    user = "checkout-user"
    meal_payload = _meal_payload(logged_at=datetime.now(UTC) - timedelta(hours=2))
    assert client.post("/meals", headers={"X-User-Id": user}, json=meal_payload).status_code == 200

    generated = client.post("/cart/generate", headers={"X-User-Id": user}, json={})
    assert generated.status_code == 200
    draft_id = generated.json()["draft"]["id"]

    checkout = client.post(
        "/cart/checkout",
        headers={"X-User-Id": user},
        json={"draftID": draft_id},
    )
    assert checkout.status_code == 200
    updated = checkout.json()["draft"]
    assert updated["checkoutURL"] is not None
    assert draft_id in updated["checkoutURL"]
    assert "instacart.com" in updated["checkoutURL"]

    latest = client.get("/cart/latest", headers={"X-User-Id": user})
    assert latest.status_code == 200
    assert latest.json()["draft"]["checkoutURL"] == updated["checkoutURL"]


def test_generate_cart_without_any_meal_returns_404(client: TestClient) -> None:
    response = client.post("/cart/generate", headers={"X-User-Id": "empty-cart-user"}, json={})
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "cart_source_missing"


def test_latest_cart_returns_null_without_draft(client: TestClient) -> None:
    response = client.get("/cart/latest", headers={"X-User-Id": "no-draft-user"})
    assert response.status_code == 200
    assert response.json()["draft"] is None


def test_prepare_checkout_without_draft_returns_404(client: TestClient) -> None:
    response = client.post("/cart/checkout", headers={"X-User-Id": "missing-draft-user"}, json={})
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "cart_not_found"
