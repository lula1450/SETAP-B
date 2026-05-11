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
    """A vet appointment can be created for a pet."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-06-15",
            "appointment_time": "10:00:00",
            "notes": "Annual checkup",
            "reminder_frequency": "once"
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
            "appointment_time": "09:30:00",
            "reminder_frequency": "once"
        })
        response = await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 1


@pytest.mark.asyncio
async def test_update_appointment(pet_in_db):
    """A vet appointment's date and time can be updated."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-08-01",
            "appointment_time": "11:00:00",
            "reminder_frequency": "once"
        })
        appt_id = (await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")).json()[0]["pet_appointment_id"]

        response = await ac.put(f"/schedule/appointments/{appt_id}", json={
            "new_date": "2027-08-15",
            "new_time": "14:00:00",
            "notes": "Rescheduled"
        })
        assert response.status_code == 200


@pytest.mark.asyncio
async def test_delete_appointment(pet_in_db):
    """A vet appointment can be deleted."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-09-01",
            "appointment_time": "10:00:00",
            "reminder_frequency": "once"
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


@pytest.mark.asyncio
async def test_get_appointments_none_returns_empty(pet_in_db):
    """Getting appointments for an owner with none returns an empty list."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")
        assert response.status_code == 200
        assert response.json() == []


@pytest.mark.asyncio
async def test_appointment_status_defaults_to_scheduled(pet_in_db):
    """A newly created appointment has a status of Scheduled by default."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-10-01",
            "appointment_time": "10:00:00",
            "reminder_frequency": "once"
        })
        appointments = await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")
        appt = appointments.json()[0]
        assert appt["appointment_status"] == "Scheduled"


@pytest.mark.asyncio
async def test_create_multiple_appointments_same_pet(pet_in_db):
    """Multiple appointments can be created for the same pet."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-11-01",
            "appointment_time": "09:00:00",
            "reminder_frequency": "once"
        })
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-12-01",
            "appointment_time": "10:00:00",
            "reminder_frequency": "once"
        })
        response = await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 2


@pytest.mark.asyncio
async def test_create_appointment_missing_fields(pet_in_db):
    """Creating an appointment with missing required fields returns 422."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id
        })
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_weekly_reminder_creates_multiple_appointments(pet_in_db):
    """Setting weekly reminder frequency creates multiple appointment entries."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-06-01",
            "appointment_time": "10:00:00",
            "reminder_frequency": "weekly"
        })
        response = await ac.get(f"/schedule/appointments/owner/{owner.owner_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 4


@pytest.mark.asyncio
async def test_get_pending_reminders(pet_in_db):
    """Pending reminders for an owner can be retrieved."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-06-15",
            "appointment_time": "10:00:00",
            "reminder_frequency": "once"
        })
        response = await ac.get(f"/schedule/reminders/pending/{owner.owner_id}")
        assert response.status_code == 200
        assert isinstance(response.json(), list)


@pytest.mark.asyncio
async def test_feeding_schedule_creates_reminder(pet_in_db):
    """Creating a feeding schedule automatically creates a reminder."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/feeding-schedules", json={
            "pet_id": pet.pet_id,
            "feeding_time": "08:00:00",
            "food_type": "Dry Kibble"
        })
        response = await ac.get(f"/schedule/reminders/pending/{owner.owner_id}")
        assert response.status_code == 200
        feeding_reminders = [r for r in response.json() if r["type"] == "feeding"]
        assert len(feeding_reminders) >= 1


@pytest.mark.asyncio
async def test_update_reminder_status(pet_in_db):
    """A reminder's status can be updated to dismissed."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-06-15",
            "appointment_time": "10:00:00",
            "reminder_frequency": "once"
        })
        reminders = await ac.get(f"/schedule/reminders/pending/{owner.owner_id}")
        reminder_id = reminders.json()[0]["reminder_id"]

        response = await ac.patch(f"/schedule/reminders/{reminder_id}/status", json={
            "status": "dismissed"
        })
        assert response.status_code == 200


@pytest.mark.asyncio
async def test_update_reminder_invalid_status(pet_in_db):
    """Updating a reminder with an invalid status returns 400."""
    owner, pet = pet_in_db
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/schedule/appointments", json={
            "pet_id": pet.pet_id,
            "appointment_date": "2027-06-15",
            "appointment_time": "10:00:00",
            "reminder_frequency": "once"
        })
        reminders = await ac.get(f"/schedule/reminders/pending/{owner.owner_id}")
        reminder_id = reminders.json()[0]["reminder_id"]

        response = await ac.patch(f"/schedule/reminders/{reminder_id}/status", json={
            "status": "invalid_status"
        })
        assert response.status_code == 400