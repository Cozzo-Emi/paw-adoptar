import pytest


@pytest.mark.asyncio
async def test_create_match(client, donor_token, pet_data):
    # Create a pet as donor
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    # Register an adopter and create a match
    adopter_data = {
        "email": "match_adopter@test.com",
        "password": "test12345",
        "full_name": "Adopter Match",
        "role": "adopter",
    }
    await client.post("/auth/register", json=adopter_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": adopter_data["email"], "password": adopter_data["password"]},
    )
    adopter_token = login_resp.json()["access_token"]

    response = await client.post(
        "/matches",
        json={"pet_id": pet_id, "adopter_message": "Me interesa!"},
        headers={"Authorization": f"Bearer {adopter_token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "pending"
    assert data["pet_id"] == pet_id
    assert data["adopter_message"] == "Me interesa!"


@pytest.mark.asyncio
async def test_create_match_own_pet(client, donor_token, pet_data):
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    response = await client.post(
        "/matches",
        json={"pet_id": pet_id},
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_accept_match(client, donor_token, pet_data):
    # Create pet
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    # Create adopter and match
    adopter_data = {
        "email": "accept_adopter@test.com",
        "password": "test12345",
        "full_name": "Accept Adopter",
        "role": "adopter",
    }
    await client.post("/auth/register", json=adopter_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": adopter_data["email"], "password": adopter_data["password"]},
    )
    adopter_token = login_resp.json()["access_token"]

    match_resp = await client.post(
        "/matches",
        json={"pet_id": pet_id},
        headers={"Authorization": f"Bearer {adopter_token}"},
    )
    match_id = match_resp.json()["id"]

    # Donor accepts
    response = await client.put(
        f"/matches/{match_id}/accept",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "accepted"


@pytest.mark.asyncio
async def test_reject_match(client, donor_token, pet_data):
    # Create pet
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    # Create adopter and match
    adopter_data = {
        "email": "reject_adopter@test.com",
        "password": "test12345",
        "full_name": "Reject Adopter",
        "role": "adopter",
    }
    await client.post("/auth/register", json=adopter_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": adopter_data["email"], "password": adopter_data["password"]},
    )
    adopter_token = login_resp.json()["access_token"]

    match_resp = await client.post(
        "/matches",
        json={"pet_id": pet_id},
        headers={"Authorization": f"Bearer {adopter_token}"},
    )
    match_id = match_resp.json()["id"]

    # Donor rejects
    response = await client.put(
        f"/matches/{match_id}/reject",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "rejected"


@pytest.mark.asyncio
async def test_list_my_matches(client, donor_token, adopter_token, pet_data):
    # Create pet
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    # Create adopter from fixture
    register_data = {
        "email": "list_adopter@test.com",
        "password": "test12345",
        "full_name": "List Adopter",
        "role": "adopter",
    }
    await client.post("/auth/register", json=register_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": register_data["email"], "password": register_data["password"]},
    )
    list_adopter_token = login_resp.json()["access_token"]

    await client.post(
        "/matches",
        json={"pet_id": pet_id},
        headers={"Authorization": f"Bearer {list_adopter_token}"},
    )

    # Check donor sees the match
    response = await client.get(
        "/matches/me",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    matches = response.json()
    assert len(matches) >= 1
    assert matches[0]["pet_name"] == pet_data["name"]
    assert matches[0]["adopter_name"] == register_data["full_name"]


@pytest.mark.asyncio
async def test_match_enriched_names(client, donor_token, pet_data):
    # Create pet
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    # Create adopter
    adopter_data = {
        "email": "names_adopter@test.com",
        "password": "test12345",
        "full_name": "Names Adopter",
        "role": "adopter",
    }
    await client.post("/auth/register", json=adopter_data)
    login_resp = await client.post(
        "/auth/login",
        data={"username": adopter_data["email"], "password": adopter_data["password"]},
    )
    adopter_token = login_resp.json()["access_token"]

    await client.post(
        "/matches",
        json={"pet_id": pet_id},
        headers={"Authorization": f"Bearer {adopter_token}"},
    )

    # Verify donor sees enriched names
    donor_info = await client.get(
        "/users/me",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    donor_name = donor_info.json()["full_name"]

    response = await client.get(
        "/matches/me",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    matches = response.json()
    assert len(matches) >= 1
    assert matches[0]["pet_name"] == pet_data["name"]
    assert matches[0]["adopter_name"] == adopter_data["full_name"]
    assert matches[0]["donor_name"] == donor_name
