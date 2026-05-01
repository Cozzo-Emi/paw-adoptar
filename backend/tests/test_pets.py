import pytest


@pytest.fixture
def pet_data():
    return {
        "name": "Firulais",
        "species": "dog",
        "age_months": 12,
        "sex": "male",
        "size": "medium",
        "description": "Perro amigable y juguetón",
        "photos": [
            {
                "cloudinary_url": "https://res.cloudinary.com/demo/image/upload/v1/pet1.jpg",
                "cloudinary_public_id": "pet1",
            },
            {
                "cloudinary_url": "https://res.cloudinary.com/demo/image/upload/v1/pet2.jpg",
                "cloudinary_public_id": "pet2",
            },
        ],
    }


@pytest.mark.asyncio
async def test_create_pet(client, donor_token, pet_data):
    response = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == pet_data["name"]
    assert data["species"] == "dog"
    assert data["status"] == "available"
    assert len(data["photos"]) == 2


@pytest.mark.asyncio
async def test_create_pet_as_adopter(client, adopter_token, pet_data):
    response = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {adopter_token}"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_create_pet_without_photos(client, donor_token, pet_data):
    data = {**pet_data, "photos": [pet_data["photos"][0]]}
    response = await client.post(
        "/pets",
        json=data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_list_pets(client, donor_token, pet_data):
    await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )

    response = await client.get(
        "/pets",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    pets = response.json()
    assert len(pets) >= 1
    assert pets[0]["status"] == "available"


@pytest.mark.asyncio
async def test_list_pets_with_filters(client, donor_token, pet_data):
    await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )

    response = await client.get(
        "/pets?species=dog",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    for pet in response.json():
        assert pet["species"] == "dog"

    response = await client.get(
        "/pets?species=cat",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    assert len(response.json()) == 0


@pytest.mark.asyncio
async def test_list_pets_by_donor(client, donor_token, pet_data):
    donor_info = await client.get(
        "/users/me",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    donor_id = donor_info.json()["id"]

    await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )

    response = await client.get(
        f"/pets?donor_id={donor_id}",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    pets = response.json()
    assert len(pets) >= 1
    assert all(p["donor_id"] == donor_id for p in pets)


@pytest.mark.asyncio
async def test_get_pet_detail(client, donor_token, pet_data):
    create_resp = await client.post(
        "/pets",
        json=pet_data,
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    pet_id = create_resp.json()["id"]

    response = await client.get(
        f"/pets/{pet_id}",
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert response.status_code == 200
    assert response.json()["id"] == pet_id
    assert response.json()["name"] == pet_data["name"]


@pytest.mark.asyncio
async def test_health_check(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
