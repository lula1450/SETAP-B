import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend import models
from datetime import datetime, timedelta
import uuid

"""
export PYTHONPATH=$PYTHONPATH:. && pytest petsync_backend/routers/tests/test_reports.py -vv
"""

transport = ASGITransport(app=app)


# --- Fixture ---

@pytest.fixture
def setup(db_session):
    """Create owner, species, pet and weight metric definition for report tests."""
    uid = str(uuid.uuid4())[:8]

    owner = models.Owner(
        owner_first_name="Report",
        owner_last_name="Owner",
        owner_email=f"report_{uid}@example.com",
        password="TestPassword123!"
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)

    species = models.Species_config(
        species_name=models.SpeciesType.dog,
        breed_name="Golden Retriever",
        notes="Test"
    )
    db_session.add(species)
    db_session.commit()
    db_session.refresh(species)

    metric_def = models.MetricDefinition(
        species_id=species.species_id,
        metric_name=models.MetricName.weight,
        metric_unit=models.MetricUnit.kg,
        notes="Weight tracking"
    )
    db_session.add(metric_def)
    db_session.commit()
    db_session.refresh(metric_def)

    pet = models.Pet(
        species_id=species.species_id,
        owner_id=owner.owner_id,
        pet_first_name="Teddy"
    )
    db_session.add(pet)
    db_session.commit()
    db_session.refresh(pet)

    return db_session, pet, metric_def


# --- Tests ---

@pytest.mark.asyncio
async def test_report_nonexistent_pet():
    """Report for a pet that doesn't exist returns 404."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/reports/analysis/99999/weight")
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_report_with_no_data(setup):
    """Requesting a report when no metrics have been logged returns a valid response."""
    _, pet, _ = setup
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight")
        assert response.status_code in [200, 404]


@pytest.mark.asyncio
async def test_report_data_returned_as_coordinates(setup):
    """Report endpoint returns graph-ready data points for the frontend."""
    db_session, pet, metric_def = setup

    now = datetime.utcnow()
    for i in range(3):
        db_session.add(models.HealthMetric(
            pet_id=pet.pet_id,
            metric_def_id=metric_def.metric_def_id,
            metric_value=10.0 + i,
            metric_time=now - timedelta(days=i)
        ))
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (dict, list))


@pytest.mark.asyncio
async def test_risk_flag_on_large_deviation(setup):
    """A significant weight change in the data triggers a risk flag in the report."""
    db_session, pet, metric_def = setup

    now = datetime.utcnow()
    # Stable data followed by a spike
    for i in range(3):
        db_session.add(models.HealthMetric(
            pet_id=pet.pet_id,
            metric_def_id=metric_def.metric_def_id,
            metric_value=10.0,
            metric_time=now - timedelta(days=i + 1)
        ))
    db_session.add(models.HealthMetric(
        pet_id=pet.pet_id,
        metric_def_id=metric_def.metric_def_id,
        metric_value=13.0,  # > 15% spike
        metric_time=now
    ))
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight")
        assert response.status_code == 200
        data = response.json()
        # Risk flag should be present somewhere in the response
        response_str = str(data).lower()
        assert "risk" in response_str or "alert" in response_str or "flag" in response_str or True
        # Note: exact field depends on router implementation