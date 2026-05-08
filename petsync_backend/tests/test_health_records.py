import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend.models import (
    MetricDefinition, MetricName, MetricUnit,
    Species_config, SpeciesType, Pet, Owner
)
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_health_records.py -vv
"""

transport = ASGITransport(app=app)


# --- Fixture ---

@pytest.fixture
def setup(db_session):
    """Create owner, species, pet and weight metric definition."""
    uid = str(uuid.uuid4())[:8]

    owner = Owner(
        owner_first_name="Record",
        owner_last_name="Owner",
        owner_email=f"record_{uid}@example.com",
        password="TestPassword123!"
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)

    species = Species_config(
        species_name=SpeciesType.rabbit,
        breed_name="Lop",
        notes="Test"
    )
    db_session.add(species)
    db_session.commit()
    db_session.refresh(species)

    pet = Pet(
        pet_first_name="Flopsy",
        owner_id=owner.owner_id,
        species_id=species.species_id
    )
    db_session.add(pet)
    db_session.commit()
    db_session.refresh(pet)

    db_session.add_all([
        MetricDefinition(species_id=species.species_id, metric_name=MetricName.weight, metric_unit=MetricUnit.kg),
        MetricDefinition(species_id=species.species_id, metric_name=MetricName.notes, metric_unit=MetricUnit.text),
    ])
    db_session.commit()

    return db_session, pet.pet_id


# --- Tests ---

@pytest.mark.asyncio
async def test_health_history_is_stored(setup):
    """Logged health metrics appear in the pet's history."""
    _, pet_id = setup
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 2.1})
        response = await ac.get(f"/health/history/{pet_id}")
        assert response.status_code == 200
        assert len(response.json()) >= 1


@pytest.mark.asyncio
async def test_history_most_recent_first(setup):
    """Health history is returned most recent first."""
    _, pet_id = setup
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 2.0})
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 2.5})
        response = await ac.get(f"/health/history/{pet_id}")
        data = response.json()
        assert data[0]["value"] == 2.5
        assert data[1]["value"] == 2.0


@pytest.mark.asyncio
async def test_history_entry_has_required_fields(setup):
    """Each history entry includes metric name, value, unit, and time."""
    _, pet_id = setup
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 2.3})
        response = await ac.get(f"/health/history/{pet_id}")
        entry = response.json()[0]
        assert "metric" in entry
        assert "value" in entry
        assert "unit" in entry
        assert "time" in entry


@pytest.mark.asyncio
async def test_delete_specific_health_entry(setup):
    """A specific health log entry can be deleted by its ID."""
    _, pet_id = setup
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 2.4})
        history = await ac.get(f"/health/history/{pet_id}")
        entry_id = history.json()[0]["id"]

        response = await ac.delete(f"/health/history/entry/{pet_id}/{entry_id}")
        assert response.status_code == 200

        history_after = await ac.get(f"/health/history/{pet_id}")
        ids_after = [e["id"] for e in history_after.json()]
        assert entry_id not in ids_after


@pytest.mark.asyncio
async def test_delete_all_metric_entries(setup):
    """All logs for a specific metric can be cleared at once."""
    _, pet_id = setup
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 2.0})
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 2.2})

        response = await ac.delete(f"/health/all/{pet_id}/weight")
        assert response.status_code == 200

        history = await ac.get(f"/health/history/{pet_id}")
        weight_entries = [e for e in history.json() if e["metric"] == "weight"]
        assert len(weight_entries) == 0


@pytest.mark.asyncio
async def test_delete_nonexistent_entry(setup):
    """Deleting a log entry that doesn't exist returns 404."""
    _, pet_id = setup
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.delete(f"/health/history/entry/{pet_id}/99999")
        assert response.status_code == 404