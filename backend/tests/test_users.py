import pytest


@pytest.mark.asyncio
async def test_get_my_user(client, user_data):
    await client.post("/auth/register", json=user_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    token = login_resp.json()["access_token"]

    response = await client.get(
        "/users/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == user_data["email"]
    assert data["full_name"] == user_data["full_name"]


@pytest.mark.asyncio
async def test_get_user_unauthorized(client):
    response = await client.get("/users/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_update_my_user(client, user_data):
    await client.post("/auth/register", json=user_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    token = login_resp.json()["access_token"]

    response = await client.put(
        "/users/me",
        json={"role": "both", "city": "Buenos Aires"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "both"
    assert data["city"] == "Buenos Aires"


@pytest.mark.asyncio
async def test_update_fcm_token(client, user_data):
    await client.post("/auth/register", json=user_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    token = login_resp.json()["access_token"]

    response = await client.post(
        "/users/me/fcm-token",
        json={"token": "fcm_test_token_123"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "success"


@pytest.mark.asyncio
async def test_get_user_by_id(client, user_data):
    register_resp = await client.post("/auth/register", json=user_data)
    user_id = register_resp.json()["id"]

    await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )

    # Register another user to get a valid token
    user2 = {**user_data, "email": "other@test.com"}
    await client.post("/auth/register", json=user2)
    login_resp2 = await client.post(
        "/auth/login",
        data={"username": user2["email"], "password": user2["password"]},
    )
    token = login_resp2.json()["access_token"]

    response = await client.get(
        f"/users/{user_id}", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert response.json()["id"] == user_id
