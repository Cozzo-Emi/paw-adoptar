import pytest


@pytest.mark.asyncio
async def test_register_user(client, user_data):
    response = await client.post("/auth/register", json=user_data)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == user_data["email"]
    assert data["full_name"] == user_data["full_name"]
    assert data["role"] == "adopter"
    assert "id" in data
    assert "password" not in data
    assert "hashed_password" not in data


@pytest.mark.asyncio
async def test_register_duplicate_email(client, user_data):
    await client.post("/auth/register", json=user_data)
    response = await client.post("/auth/register", json=user_data)
    assert response.status_code == 400
    assert "already exists" in response.json()["detail"]


@pytest.mark.asyncio
async def test_register_short_password(client, user_data):
    data = {**user_data, "password": "123"}
    response = await client.post("/auth/register", json=data)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_login_success(client, user_data):
    await client.post("/auth/register", json=user_data)

    response = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_wrong_password(client, user_data):
    await client.post("/auth/register", json=user_data)

    response = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": "wrongpassword"},
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_login_wrong_email(client):
    response = await client.post(
        "/auth/login",
        data={"username": "noexiste@test.com", "password": "test12345"},
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_refresh_token(client, user_data):
    await client.post("/auth/register", json=user_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    refresh_token = login_resp.json()["refresh_token"]

    response = await client.post(
        "/auth/refresh", json={"refresh_token": refresh_token}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_refresh_token_invalid(client):
    response = await client.post(
        "/auth/refresh", json={"refresh_token": "token_invalido"}
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_with_access_token(client, user_data):
    await client.post("/auth/register", json=user_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": user_data["email"], "password": user_data["password"]},
    )
    access_token = login_resp.json()["access_token"]

    response = await client.post(
        "/auth/refresh", json={"refresh_token": access_token}
    )
    assert response.status_code == 401
