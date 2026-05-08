from concurrent.interpreters import create

import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend import models
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_notifications.py -vv
"""

transport = ASGITransport(app=app)


# --- Helper ---

@pytest.fixture
def pet_in_db(db_session):
    """Create a basic owner, species, and pet for appointment/reminder tests."""
    uid = str(uuid.uuid4())[:8]
    owner = models.Owner(
        owner_first_name="Notif",
        owner_last_name="Owner",
        owner_email=f"notif_{uid}@example.com",
        password="TestPassword123!"
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)

    species = models.Species_config(
        species_name=models.SpeciesType.cat,
        breed_name="Tabby",
        notes="Test"
    )
    db_session.add(species)
    db_session.commit()
    db_session.refresh(species)

    pet = models.Pet(
        pet_first_name="Whiskers",
        owner_id=owner.owner_id,
        species_id=species.species_id
    )
    db_session.add(pet)
    db_session.commit()
    db_session.refresh(pet)

    return owner, pet


# --- Appointment Tests ---

@pytest.mark.asyncio
async def test_create_appointment(pet_in_db):
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-06-15",
            "appointment_time": "10:00:00",
            "notes": "Annual checkup"
        })
        assert response.status_code == 201


@pytest.mark.asyncio
async def test_get_appointments_for_owner(pet_in_db):
    """All vet appointments for an owner's pets can be retrieved."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-07-10",
            "appointment_time": "09:30:00"
        })
        response = await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 1


@pytest.mark.asyncio
async def test_update_appointment(pet_in_db):
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        create = await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-08-01",
            "appointment_time": "11:00:00"
        })
        assert create.status_code == 201
        appt_id = create.json()["pet_appointment_id"] if "pet_appointment_id" in create.json() else create.json().get("id")
        if not appt_id:
            appt_id = (await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")).json()[0]["pet_appointment_id"]
        
        response = await ac.put(f"/schedule/appointments/{appt_id}", json={
            "new_date": "2027-08-15",
            "new_time": "14:00:00",
            "notes": "Rescheduled"
        })
        assert response.status_code == 200


@pytest.mark.asyncio
async def test_delete_appointment(pet_in_db):
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-09-01",
            "appointment_time": "10:00:00"
        })
        appt_id = (await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")).json()[0]["pet_appointment_id"]
        
        response = await ac.delete(f"/schedule/appointments/{appt_id}")
        assert response.status_code == 204


@pytest.mark.asyncio
async def test_delete_nonexistent_appointment():
    """Deleting an appointment that doesn't exist returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.delete("/schedule/appointments/99999")
        assert response.status_code == 404