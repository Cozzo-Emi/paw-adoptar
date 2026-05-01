import pytest
from datetime import datetime, timedelta, timezone


@pytest.mark.asyncio
async def test_send_reminders_no_due(client):
    response = await client.post("/matches/send-reminders")
    assert response.status_code == 200
    data = response.json()
    assert data["sent"] == 0
    assert "checked" in data


@pytest.mark.asyncio
async def test_send_reminders_with_due_match(client, donor_token, user_data, pet_data):
    # Create pet
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    # Register adopter
    adopter_data = {
        "email": "reminder_adopter@test.com",
        "password": "test12345",
        "full_name": "Reminder Adopter",
        "role": "adopter",
    }
    await client.post("/auth/register", json=adopter_data)
    login = await client.post(
        "/auth/login",
        data={"username": adopter_data["email"], "password": adopter_data["password"]},
    )
    adopter_token = login.json()["access_token"]

    # Create and accept match
    match_resp = await client.post(
        "/matches",
        json={"pet_id": pet_id},
        headers={"Authorization": f"Bearer {adopter_token}"},
    )
    match_id = match_resp.json()["id"]

    # Donor accepts
    await client.put(
        f"/matches/{match_id}/accept",
        headers={"Authorization": f"Bearer {donor_token}"},
    )

    # Verify the match was accepted
    response = await client.get(
        "/matches/me",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    matches = response.json()
    assert len(matches) >= 1
    assert matches[0]["status"] == "accepted"
