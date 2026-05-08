import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend import models
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_feeding_schedule.py -vv
"""

transport = ASGITransport(app=app)


# --- Helper ---

@pytest.fixture
def pet_in_db(db_session):
    """Create a basic owner, species, and pet for feeding schedule tests."""
    uid = str(uuid.uuid4())[:8]
    owner = models.Owner(
        owner_first_name="Feed",
        owner_last_name="Owner",
        owner_email=f"feed_{uid}@example.com",
        password="TestPassword123!"
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)

    species = models.Species_config(
        species_name=models.SpeciesType.dog,
        breed_name="Labrador",
        notes="Test"
    )
    db_session.add(species)
    db_session.commit()
    db_session.refresh(species)

    pet = models.Pet(
        pet_first_name="Rex",
        owner_id=owner.owner_id,
        species_id=species.species_id
    )
    db_session.add(pet)
    db_session.commit()
    db_session.refresh(pet)

    return pet


# --- Tests ---

@pytest.mark.asyncio
async def test_create_feeding_schedule(pet_in_db):
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet_in_db.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        assert response.status_code == 201

@pytest.mark.asyncio
async def test_get_feeding_schedules(pet_in_db):
    """Feeding schedules for a pet can be retrieved."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet_in_db.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet_in_db.pet_id,
            "feeding_time": "18:00:00",
            "food_type": "Wet Food"
        })

        response = await ac.get(f"/schedule/feeding-schedules/pet/{pet_in_db.pet_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 2


@pytest.mark.asyncio
async def test_get_feeding_schedules_no_results(pet_in_db):
    """Retrieving schedules for a pet with none returns an empty list."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/schedule/feeding-schedules/pet/{pet_in_db.pet_id}")
        assert response.status_code == 200
        assert response.json() == []


@pytest.mark.asyncio
async def test_multiple_feeding_times(pet_in_db):
    """Multiple feeding times can be created for a pet (e.g. fed 3x per day)."""
    times = ["07:00:00", "12:00:00", "19:00:00"]
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        for t in times:
            resp = await ac.post("/schedule/feeding-schedules", json={
                "pet_id": pet_in_db.pet_id,
                "feeding_time": t,
                "food_type": "Kibble"
            })
            assert resp.status_code == 201

        response = await ac.get(f"/schedule/feeding-schedules/pet/{pet_in_db.pet_id}")
        assert len(response.json()) >= 3