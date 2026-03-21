import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend.models import (
    MetricDefinition, MetricName, 
    MetricUnit, Species_config, SpeciesType
)

import pytest_asyncio

# Use the same transport as test_pets.py
transport = ASGITransport(app=app)

# -----------------------------
# Fixture for setup
# -----------------------------
@pytest_asyncio.fixture
async def setup_metrics(db_session): # Uses the shared db_session from conftest
    # 1. Create Species record
    test_species = Species_config(
        species_name=SpeciesType.dog,
        breed_name="Golden Retriever",
        notes="Test species"
    )
    db_session.add(test_species)
    db_session.commit()
    db_session.refresh(test_species)

    # 2. Create all required Metric Definitions
    metrics = [
        MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.weight, metric_unit=MetricUnit.kg),
        MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.notes, metric_unit=MetricUnit.text),
    ]
    db_session.add_all(metrics)
    db_session.commit()
    return db_session

# -----------------------------
# Async Test Cases
# -----------------------------

@pytest.mark.asyncio
async def test_log_health_metric(setup_metrics):
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        payload = {"pet_id": 1, "metric_name": "weight", "value": 4.5, "notes": "Pet is doing well"}
        # Ensure this path matches your router!
        response = await ac.post("/health/log", json=payload)
        assert response.status_code == 200
        assert response.json()["status"] == "Logged"

@pytest.mark.asyncio
async def test_weight_alert(setup_metrics):
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        await ac.post("/health/log", json={"pet_id": 2, "metric_name": "weight", "value": 4.0})
        response = await ac.post("/health/log", json={"pet_id": 2, "metric_name": "weight", "value": 5.0})
        assert "ALERT" in response.json()["analysis"]

@pytest.mark.asyncio
async def test_non_numeric_metric(setup_metrics):
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        payload = {"pet_id": 4, "metric_name": "weight", "value": "not_a_number", "notes": ""}
        response = await ac.post("/health/log", json=payload)
        # Match your router's specific Error return
        assert response.json()["status"] == "Error"
        assert "ERROR" in response.json()["analysis"]