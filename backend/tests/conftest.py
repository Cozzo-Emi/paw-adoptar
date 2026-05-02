import os

os.environ["APP_ENV"] = "testing"

from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.database import Base, get_db
from app.main import app

TEST_DATABASE_URL = (
    "postgresql+asyncpg://paw_user:paw_secret_dev@db:5432/paw_test"
)


@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()


@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    session_factory = async_sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with session_factory() as session:
            try:
                yield session
            finally:
                await session.close()

    app.dependency_overrides[get_db] = override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()
    await engine.dispose()


@pytest.fixture
def user_data():
    return {
        "email": "test@example.com",
        "password": "test12345",
        "full_name": "Test User",
        "role": "adopter",
    }


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


@pytest_asyncio.fixture
async def donor_token(client, user_data):
    resp = await client.post(
        "/auth/register",
        json={**user_data, "role": "donor", "email": "donor@test.com"},
    )
    login = await client.post(
        "/auth/login",
        data={"username": "donor@test.com", "password": user_data["password"]},
    )
    return login.json()["access_token"]


@pytest_asyncio.fixture
async def adopter_token(client, user_data):
    await client.post(
        "/auth/register",
        json={**user_data, "role": "adopter", "email": "adopter@test.com"},
    )
    login = await client.post(
        "/auth/login",
        data={"username": "adopter@test.com", "password": user_data["password"]},
    )
    return login.json()["access_token"]
