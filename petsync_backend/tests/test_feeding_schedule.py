import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend import models
from petsync_backend.tests._test_state import _current_test_owner_id
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_feeding_schedule.py -vv
"""

transport = ASGITransport(app=app)


# Helper

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

    _current_test_owner_id[0] = owner.owner_id
    return owner, pet


# Tests

@pytest.mark.asyncio
async def test_create_feeding_schedule(pet_in_db):
    """A feeding schedule can be created for a pet."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        assert response.status_code == 201


@pytest.mark.asyncio
async def test_get_feeding_schedules(pet_in_db):
    """Feeding schedules for a pet can be retrieved."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "18:00:00",
            "food_type": "Wet Food"
        })
        response = await ac.get(f"/schedule/feeding-schedules/pet/{pet.pet_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 2


@pytest.mark.asyncio
async def test_get_feeding_schedules_no_results(pet_in_db):
    """Retrieving schedules for a pet with none returns an empty list."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/schedule/feeding-schedules/pet/{pet.pet_id}")
        assert response.status_code == 200
        assert response.json() == []


@pytest.mark.asyncio
async def test_multiple_feeding_times(pet_in_db):
    """Multiple feeding times can be created for a pet (e.g. fed 3x per day)."""
    owner, pet = pet_in_db
    times = ["07:00:00", "12:00:00", "19:00:00"]
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        for t in times:
            resp = await ac.post("/schedule/feeding-schedules", json={
                "pet_id": pet.pet_id,
                "feeding_time": t,
                "food_type": "Kibble"
            })
            assert resp.status_code == 201

        response = await ac.get(f"/schedule/feeding-schedules/pet/{pet.pet_id}")
        assert len(response.json()) >= 3


@pytest.mark.asyncio
async def test_create_feeding_schedule_missing_fields(pet_in_db):
    """Creating a feeding schedule with missing fields returns 422."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id
        })
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_different_food_types(pet_in_db):
    """Different food types can be stored in separate feeding schedules."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "18:00:00",
            "food_type": "Wet Food"
        })
        response = await ac.get(f"/schedule/feeding-schedules/pet/{pet.pet_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 2


@pytest.mark.asyncio
async def test_feeding_schedule_once_a_day(pet_in_db):
    """A single daily feeding time can be created for pets fed once a day."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "09:00:00",
            "food_type": "Premium Kibble"
        })
        assert response.status_code == 201
        schedules = await ac.get(f"/schedule/feeding-schedules/pet/{pet.pet_id}")
        assert len(schedules.json()) >= 1


@pytest.mark.asyncio
async def test_feeding_schedule_creates_reminder(pet_in_db):
    """Creating a feeding schedule automatically generates a reminder."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        assert response.status_code == 201
        reminders = await ac.get(f"/schedule/reminders/pending/{owner.owner_id}")
        assert reminders.status_code == 200
        feeding_reminders = [r for r in reminders.json() if r["type"] == "feeding"]
        assert len(feeding_reminders) >= 1


@pytest.mark.asyncio
async def test_feeding_schedule_food_name_stored(pet_in_db):
    """The food type name is correctly stored in the feeding schedule."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Royal Canin"
        })
        schedules = await ac.get(f"/schedule/feeding-schedules/pet/{pet.pet_id}")
        assert schedules.status_code == 200
        food_names = [s["food_name"] for s in schedules.json()]
        assert "Royal Canin" in food_names


@pytest.mark.asyncio
async def test_feeding_schedule_has_start_and_end_date(pet_in_db):
    """A created feeding schedule includes a start and end date in the response."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        schedules = await ac.get(f"/schedule/feeding-schedules/pet/{pet.pet_id}")
        assert schedules.status_code == 200
        entry = schedules.json()[0]
        assert "feeding_schedule_start" in entry
        assert "feeding_schedule_end" in entry