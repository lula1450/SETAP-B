import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend.models import (
    MetricDefinition, MetricName,
    MetricUnit, Species_config, SpeciesType, Pet, Owner
)
from petsync_backend.tests._test_state import _current_test_owner_id
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_health.py -vv
"""

transport = ASGITransport(app=app)


# --- Fixture ---

@pytest.fixture
def setup_metrics(db_session):
    """Create an owner, species, pet and metric definitions for health tests."""
    uid = str(uuid.uuid4())[:8]

    owner = Owner(
        owner_first_name="Test",
        owner_last_name="Owner",
        owner_email=f"health_{uid}@example.com",
        password="TestPassword123!"
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)
    _current_test_owner_id[0] = owner.owner_id

    species = Species_config(
        species_name=SpeciesType.dog,
        breed_name="Golden Retriever",
        notes="Test species"
    )
    db_session.add(species)
    db_session.commit()
    db_session.refresh(species)

    pet = Pet(
        pet_first_name="Buddy",
        owner_id=owner.owner_id,
        species_id=species.species_id
    )
    db_session.add(pet)
    db_session.commit()
    db_session.refresh(pet)

    db_session.add_all([
        MetricDefinition(species_id=species.species_id, metric_name=MetricName.weight, metric_unit=MetricUnit.kg),
        MetricDefinition(species_id=species.species_id, metric_name=MetricName.notes, metric_unit=MetricUnit.text),
        MetricDefinition(species_id=species.species_id, metric_name=MetricName.energy_level, metric_unit=MetricUnit.scale_1_5),
        MetricDefinition(species_id=species.species_id, metric_name=MetricName.stool_quality, metric_unit=MetricUnit.scale_1_5),
    ])
    db_session.commit()

    return db_session, pet.pet_id


# --- Logging Tests ---

@pytest.mark.asyncio
async def test_log_health_metric(setup_metrics):
    """A health metric can be logged for a pet."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 4.5})
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "Logged"
        assert "analysis" in data


@pytest.mark.asyncio
async def test_log_metric_invalid_pet():
    """Logging a metric for a non-existent pet returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"pet_id": 99999, "metric_name": "weight", "value": 10.0})
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_log_metric_not_defined_for_species(setup_metrics):
    """Logging a metric not configured for the pet's species returns 404."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "basking_time", "value": 30})
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_log_non_numeric_value_for_numeric_metric(setup_metrics):
    """Logging a text value for a numeric metric returns an error status."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": "not_a_number"})
        assert response.status_code == 200
        assert response.json()["status"] == "Error"


@pytest.mark.asyncio
async def test_log_text_metric(setup_metrics):
    """Text-based metrics like notes can be logged successfully."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "notes", "value": "Pet seems healthy"})
        assert response.status_code == 200
        assert response.json()["status"] == "Logged"


@pytest.mark.asyncio
async def test_log_stool_quality(setup_metrics):
    """Species-specific metrics like stool quality can be logged."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "stool_quality", "value": 3})
        assert response.status_code == 200
        assert response.json()["status"] == "Logged"


# --- Weight Alert Tests ---

@pytest.mark.asyncio
async def test_significant_weight_change_triggers_alert(setup_metrics):
    """A weight change greater than 15% triggers a health alert."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 10.0})
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 12.0})
        assert response.status_code == 200
        assert "ALERT" in response.json()["analysis"]


@pytest.mark.asyncio
async def test_stable_weight_no_alert(setup_metrics):
    """A weight change under 15% is reported as stable, no alert raised."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 10.0})
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 10.5})
        assert response.status_code == 200
        assert "Weight stable" in response.json()["analysis"]


# --- Goal Tests ---

@pytest.mark.asyncio
async def test_set_weight_goal(setup_metrics):
    """A target weight goal can be set for a pet."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/health/goal", params={"pet_id": pet_id, "metric_name": "weight", "goal": "12.0"})
        assert response.status_code == 200
        assert response.json()["status"] == "success"


@pytest.mark.asyncio
async def test_weight_over_target_flagged(setup_metrics):
    """When a pet's weight exceeds its target, the analysis flags it."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/goal", params={"pet_id": pet_id, "metric_name": "weight", "goal": "10.0"})
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 10.0})
        response = await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 12.0})
        assert "over target" in response.json()["analysis"]


# --- History & Latest Tests ---

@pytest.mark.asyncio
async def test_get_pet_history(setup_metrics):
    """Health history for a pet is returned in reverse chronological order."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 10.0})
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 11.0})
        response = await ac.get(f"/health/history/{pet_id}")
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 2
        assert data[0]["value"] == 11.0


@pytest.mark.asyncio
async def test_get_latest_metric(setup_metrics):
    """The most recently logged value is returned by the latest endpoint."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": pet_id, "metric_name": "weight", "value": 9.5})
        response = await ac.get("/health/latest", params={"pet_id": pet_id, "metric_name": "weight"})
        assert response.status_code == 200
        assert response.json()["value"] == 9.5


@pytest.mark.asyncio
async def test_get_latest_no_logs_returns_placeholder(setup_metrics):
    """When no metric has been logged yet, the latest endpoint returns '---'."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/health/latest", params={"pet_id": pet_id, "metric_name": "weight"})
        assert response.status_code == 200
        assert response.json()["value"] == "---"


@pytest.mark.asyncio
async def test_get_available_metrics(setup_metrics):
    """The metrics available for a pet are returned based on its species."""
    _, pet_id = setup_metrics
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/health/metrics/{pet_id}")
        assert response.status_code == 200
        metrics = [m["name"] for m in response.json()]
        assert "weight" in metrics