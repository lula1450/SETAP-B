import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend import models
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_pets.py -vv
"""

transport = ASGITransport(app=app)


# --- Helpers ---

def make_owner(db_session, suffix=""):
    uid = str(uuid.uuid4())[:8]
    owner = models.Owner(
        owner_first_name="Test",
        owner_last_name="Owner",
        owner_email=f"pet_owner_{uid}{suffix}@example.com",
        password="TestPassword123!"
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)
    return owner

def make_species(db_session, species_type=models.SpeciesType.dog, breed="Golden Retriever"):
    species = models.Species_config(
        species_name=species_type,
        breed_name=breed,
        notes="Test species"
    )
    db_session.add(species)
    db_session.commit()
    db_session.refresh(species)
    return species


# --- Tests ---

@pytest.mark.asyncio
async def test_create_pet(db_session):
    """A pet can be created and linked to an owner."""
    owner = make_owner(db_session)
    species = make_species(db_session)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/pets/create", json={
            "species_id": species.species_id,
            "owner_id": owner.owner_id,
            "pet_first_name": "Buddy",
            "pet_last_name": "Smith"
        })
        assert response.status_code == 200
        data = response.json()
        assert data["pet_first_name"] == "Buddy"
        assert "pet_id" in data


@pytest.mark.asyncio
async def test_create_pet_invalid_owner():
    """Creating a pet with a non-existent owner returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/pets/create", json={
            "species_id": 1,
            "owner_id": 99999,
            "pet_first_name": "Ghost"
        })
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_get_pet(db_session):
    """A created pet can be retrieved by its ID."""
    owner = make_owner(db_session)
    species = make_species(db_session)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        create = await ac.post("/pets/create", json={
            "species_id": species.species_id,
            "owner_id": owner.owner_id,
            "pet_first_name": "Luna"
        })
        pet_id = create.json()["pet_id"]

        response = await ac.get(f"/pets/{pet_id}")
        assert response.status_code == 200
        assert response.json()["pet_first_name"] == "Luna"


@pytest.mark.asyncio
async def test_get_nonexistent_pet():
    """Retrieving a pet that doesn't exist returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets/99999")
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_get_pets_for_owner(db_session):
    """All pets belonging to an owner can be listed."""
    owner = make_owner(db_session)
    species = make_species(db_session)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/pets/create", json={"species_id": species.species_id, "owner_id": owner.owner_id, "pet_first_name": "Pip"})
        await ac.post("/pets/create", json={"species_id": species.species_id, "owner_id": owner.owner_id, "pet_first_name": "Dot"})

        response = await ac.get(f"/pets/owner/{owner.owner_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 2


@pytest.mark.asyncio
async def test_get_pets_for_nonexistent_owner():
    """Listing pets for an owner with no pets returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/pets/owner/99999")
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_pet(db_session):
    """A pet's name can be updated."""
    owner = make_owner(db_session)
    species = make_species(db_session)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        create = await ac.post("/pets/create", json={
            "species_id": species.species_id,
            "owner_id": owner.owner_id,
            "pet_first_name": "Old Name"
        })
        pet_id = create.json()["pet_id"]

        response = await ac.put(f"/pets/{pet_id}", json={
            "species_id": species.species_id,
            "owner_id": owner.owner_id,
            "pet_first_name": "New Name"
        })
        assert response.status_code == 200
        assert response.json()["pet_first_name"] == "New Name"


@pytest.mark.asyncio
async def test_delete_pet(db_session):
    """A pet can be deleted and is then no longer retrievable."""
    owner = make_owner(db_session)
    species = make_species(db_session)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        create = await ac.post("/pets/create", json={
            "species_id": species.species_id,
            "owner_id": owner.owner_id,
            "pet_first_name": "Temp"
        })
        pet_id = create.json()["pet_id"]

        response = await ac.delete(f"/pets/{pet_id}")
        assert response.status_code == 200

        get_response = await ac.get(f"/pets/{pet_id}")
        assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_pet_species_returned(db_session):
    """A pet's species name is included when retrieving the pet."""
    owner = make_owner(db_session)
    species = make_species(db_session, species_type=models.SpeciesType.cat, breed="Tabby")
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        create = await ac.post("/pets/create", json={
            "species_id": species.species_id,
            "owner_id": owner.owner_id,
            "pet_first_name": "Whiskers"
        })
        pet_id = create.json()["pet_id"]
        response = await ac.get(f"/pets/{pet_id}")
        assert response.status_code == 200
        assert "cat" in response.json().get("species_name", "").lower()