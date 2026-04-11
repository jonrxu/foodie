from __future__ import annotations

from fastapi.testclient import TestClient


def test_register_user_returns_stable_id(client: TestClient) -> None:
    response = client.post(
        "/users/register",
        json={
            "displayName": "Test User",
            "dietPreferences": ["No red meat", "Low sodium"],
            "careGoals": ["Reduce spikes", "Keep glucose steady"],
            "supportPreferences": ["Meal reminders", "Grocery reminders"],
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["id"]
    assert body["displayName"] == "Test User"
    assert "Reduce spikes" in body["careGoals"]
    assert "Meal reminders" in body["supportPreferences"]
    assert "No red meat" in body["dietPreferences"]


def test_register_minimal_payload(client: TestClient) -> None:
    response = client.post("/users/register", json={})
    assert response.status_code == 200
    assert response.json()["id"]


def test_get_me_returns_registered_profile(client: TestClient) -> None:
    registered = client.post(
        "/users/register",
        json={"displayName": "Jane", "careGoals": ["Heart health"]},
    )
    user_id = registered.json()["id"]

    me = client.get("/users/me", headers={"X-User-Id": user_id})
    assert me.status_code == 200
    assert me.json()["id"] == user_id
    assert me.json()["displayName"] == "Jane"
    assert "Heart health" in me.json()["careGoals"]


def test_get_me_unknown_user_returns_404(client: TestClient) -> None:
    response = client.get("/users/me", headers={"X-User-Id": "nonexistent-user"})
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "user_not_found"
