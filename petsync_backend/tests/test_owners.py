import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend.models import Owner
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_owners.py -vv
"""

transport = ASGITransport(app=app)


# --- Fixtures ---

@pytest.fixture
def owner_data():
    """Generate unique owner data for each test."""
    uid = str(uuid.uuid4())[:8]
    return {
        "owner_first_name": "Test",
        "owner_last_name": "Owner",
        "owner_email": f"test_{uid}@example.com",
        "password": "TestPassword123!"
    }

@pytest.fixture
def create_owner(db_session):
    """Create an owner directly in the test database."""
    uid = str(uuid.uuid4())[:8]
    owner = Owner(
        owner_first_name="Test",
        owner_last_name="Owner",
        owner_email=f"test_{uid}@example.com",
        password="TestPassword123!"
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)
    return owner


# --- Tests ---

@pytest.mark.asyncio
async def test_create_owner(owner_data):
    """Owner account can be created successfully."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/owners/", json=owner_data)
        assert response.status_code == 201
        data = response.json()
        assert data["owner_first_name"] == "Test"
        assert data["owner_email"] == owner_data["owner_email"]
        assert "owner_id" in data


@pytest.mark.asyncio
async def test_create_owner_duplicate_email(owner_data):
    """Creating two accounts with the same email returns an error."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/owners/", json=owner_data)
        response = await ac.post("/owners/", json=owner_data)
        assert response.status_code == 400


@pytest.mark.asyncio
async def test_create_owner_missing_fields():
    """Creating an owner without required fields returns 422."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/owners/", json={"owner_first_name": "Test"})
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_owner(create_owner):
    """A created owner can be retrieved by ID."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/owners/{create_owner.owner_id}")
        assert response.status_code == 200
        assert response.json()["owner_email"] == create_owner.owner_email


@pytest.mark.asyncio
async def test_get_nonexistent_owner():
    """Retrieving an owner that doesn't exist returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/owners/99999")
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_owner(create_owner):
    """An owner's details can be updated."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.put(f"/owners/{create_owner.owner_id}", json={
            "owner_first_name": "Updated"
        })
        assert response.status_code == 200
        assert response.json()["owner_first_name"] == "Updated"


@pytest.mark.asyncio
async def test_delete_owner(create_owner):
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.delete(f"/owners/{create_owner.owner_id}")
        assert response.status_code == 200
        assert "scheduled for deletion" in response.json()["message"]


@pytest.mark.asyncio
async def test_delete_nonexistent_owner():
    """Deleting an owner that doesn't exist returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.delete("/owners/99999")
        assert response.status_code == 404