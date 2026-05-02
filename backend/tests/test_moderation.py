import pytest


@pytest.mark.asyncio
async def test_list_reports_unauthorized(client):
    response = await client.get("/moderation/reports")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_create_and_list_reports(client, user_data):
    # Register target user first
    target_resp = await client.post(
        "/auth/register",
        json={**user_data, "email": "target@test.com"},
    )
    target_id = target_resp.json()["id"]

    # Register a normal user
    await client.post("/auth/register", json=user_data)
    login = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    token = login.json()["access_token"]

    # Create a report as normal user
    response = await client.post(
        "/moderation/reports",
        json={
            "reported_user_id": target_id,
            "reason": "fraud",
            "description": "Test report",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    assert response.json()["status"] == "pending"
    assert response.json()["reason"] == "fraud"


@pytest.mark.asyncio
async def test_moderator_can_list_reports(client, user_data):
    # Register a moderator
    moderator_data = {
        "email": "mod@test.com",
        "password": "mod12345",
        "full_name": "Moderator",
        "role": "moderator",
    }
    await client.post("/auth/register", json=moderator_data)
    mod_login = await client.post(
        "/auth/login",
        data={"username": moderator_data["email"], "password": moderator_data["password"]},
    )
    mod_token = mod_login.json()["access_token"]

    # Register target user
    target_resp = await client.post(
        "/auth/register",
        json={**user_data, "email": "target_mod@test.com"},
    )
    target_id = target_resp.json()["id"]

    # Create a report as a normal user
    normal_data = {**user_data, "email": "normal@test.com"}
    await client.post("/auth/register", json=normal_data)
    normal_login = await client.post(
        "/auth/login",
        data={"username": normal_data["email"], "password": normal_data["password"]},
    )
    normal_token = normal_login.json()["access_token"]

    await client.post(
        "/moderation/reports",
        json={"reported_user_id": target_id, "reason": "abuse", "description": "Test abuse report"},
        headers={"Authorization": f"Bearer {normal_token}"},
    )

    # Moderator lists reports
    response = await client.get(
        "/moderation/reports",
        headers={"Authorization": f"Bearer {mod_token}"},
    )
    assert response.status_code == 200
    reports = response.json()
    assert len(reports) >= 1
    assert reports[0]["reason"] == "abuse"


@pytest.mark.asyncio
async def test_moderator_update_report(client, user_data):
    # Setup moderator
    moderator_data = {
        "email": "mod2@test.com",
        "password": "mod12345",
        "full_name": "Moderator 2",
        "role": "moderator",
    }
    await client.post("/auth/register", json=moderator_data)
    mod_login = await client.post(
        "/auth/login",
        data={"username": moderator_data["email"], "password": moderator_data["password"]},
    )
    mod_token = mod_login.json()["access_token"]

    # Register target user
    target_resp = await client.post(
        "/auth/register",
        json={**user_data, "email": "target_upd@test.com"},
    )
    target_id = target_resp.json()["id"]

    # Create user and report
    normal_data = {**user_data, "email": "normal2@test.com"}
    await client.post("/auth/register", json=normal_data)
    normal_login = await client.post(
        "/auth/login",
        data={"username": normal_data["email"], "password": normal_data["password"]},
    )
    normal_token = normal_login.json()["access_token"]

    create_resp = await client.post(
        "/moderation/reports",
        json={"reported_user_id": target_id, "reason": "fake_listing", "description": "Report to resolve"},
        headers={"Authorization": f"Bearer {normal_token}"},
    )
    report_id = create_resp.json()["id"]

    # Moderator resolves
    response = await client.put(
        f"/moderation/reports/{report_id}",
        json={"status": "resolved", "resolution_notes": "Taken down"},
        headers={"Authorization": f"Bearer {mod_token}"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "resolved"
    assert response.json()["resolution_notes"] == "Taken down"


@pytest.mark.asyncio
async def test_normal_user_cannot_update_report(client, user_data):
    # Register a normal user
    await client.post("/auth/register", json=user_data)
    login = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    token = login.json()["access_token"]

    response = await client.put(
        "/moderation/reports/some-id",
        json={"status": "resolved"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 403
