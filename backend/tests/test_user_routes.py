from __future__ import annotations

from fastapi.testclient import TestClient


def test_update_me_creates_profile_for_current_user(client: TestClient, auth_headers) -> None:
    response = client.put(
        "/users/me",
        headers=auth_headers("test-user"),
        json={
            "displayName": "Test User",
            "dietPreferences": ["No red meat", "Low sodium"],
            "careGoals": ["Reduce spikes", "Keep glucose steady"],
            "supportPreferences": ["Meal reminders", "Grocery reminders"],
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == "test-user"
    assert body["displayName"] == "Test User"
    assert body["email"] == "test-user@example.com"
    assert body["hasCompletedOnboarding"] is False
    assert "Reduce spikes" in body["careGoals"]
    assert "Meal reminders" in body["supportPreferences"]
    assert "No red meat" in body["dietPreferences"]


def test_update_me_updates_existing_profile(client: TestClient, auth_headers) -> None:
    updated = client.put(
        "/users/me",
        headers=auth_headers("jane-user"),
        json={
            "displayName": "Jane Doe",
            "dietPreferences": ["Low sodium"],
            "careGoals": ["Reduce spikes"],
            "supportPreferences": ["Weekly summary"],
            "hasCompletedOnboarding": True,
        },
    )
    assert updated.status_code == 200
    body = updated.json()
    assert body["id"] == "jane-user"
    assert body["displayName"] == "Jane Doe"
    assert body["hasCompletedOnboarding"] is True
    assert body["dietPreferences"] == ["Low sodium"]

    me = client.get("/users/me", headers=auth_headers("jane-user"))
    assert me.status_code == 200
    assert me.json()["displayName"] == "Jane Doe"
    assert me.json()["careGoals"] == ["Reduce spikes"]


def test_get_me_bootstraps_authenticated_user(client: TestClient, auth_headers) -> None:
    response = client.get("/users/me", headers=auth_headers("new-user", "new@example.com"))
    assert response.status_code == 200
    assert response.json()["id"] == "new-user"
    assert response.json()["email"] == "new@example.com"
    assert response.json()["hasCompletedOnboarding"] is False


def test_get_me_requires_authentication(client: TestClient) -> None:
    response = client.get("/users/me")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "auth_required"
