import pytest
from httpx import AsyncClient, ASGITransport
from petsync_backend.main import app
from petsync_backend import models
from datetime import datetime, timedelta
import uuid

# Setup the transport for the FastAPI app
transport = ASGITransport(app=app)

@pytest.mark.asyncio
async def test_get_report_nonexistent_pet():
    """Requirement: Return 404 if the pet ID does not exist."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/reports/analysis/9999/weight")
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

@pytest.mark.asyncio
async def test_report_data_flow(db_session):
    """
    Requirement: Verify the API fetches health logs and formats 
    them into graph coordinates for the frontend.
    """
    # 1. SETUP: Create Core Dependencies
    owner = models.Owner(
        owner_first_name="Lauren", 
        owner_last_name="Coppin",
        owner_email="lauren.test@example.com", 
        owner_phone_number="07000000000",
        owner_address1="123 Pet St", 
        owner_postcode="PO1", 
        owner_city="Portsmouth"
    )
    
    species = models.Species_config(
        species_name=models.SpeciesType.dog, 
        breed_name="Golden Retriever", 
        notes="Test species"
    )
    
    # Add them first to get IDs
    db_session.add_all([owner, species])
    db_session.commit()
    db_session.refresh(owner)
    db_session.refresh(species)

    # 2. SETUP: Create Metric Definition linked to Species
    metric_def = models.MetricDefinition(
        species_id=species.species_id,
        metric_name=models.MetricName.weight,
        metric_unit=models.MetricUnit.kg,
        notes="Weight tracking"
    )
    db_session.add(metric_def)
    db_session.commit()
    db_session.refresh(metric_def)

    # 3. SETUP: Create Pet linked to Owner and Species
    pet = models.Pet(
        species_id=species.species_id, 
        owner_id=owner.owner_id,
        pet_first_name="Teddy", 
        pet_address1="123 Pet St",
        pet_postcode="PO1", 
        pet_city="Portsmouth"
    )
    db_session.add(pet)
    db_session.commit()
    db_session.refresh(pet)

    # 4. SETUP: Add a Health Log entry
    # 4. SETUP: Add a Health Log entry
    log = models.HealthMetric(
        pet_id=pet.pet_id,
        metric_def_id=metric_def.metric_def_id,
        metric_value=15.5,
        metric_time=datetime.utcnow()
    )
    db_session.add(log)
    db_session.commit()
    
    # NEW: Force the session to expire everything so it fetches fresh from the disk
    db_session.expire_all() 

    # 5. TEST: Hit the API
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        url = f"/reports/analysis/{pet.pet_id}/weight"
        response = await ac.get(url)
        
        # DEBUG: If it fails, show the detail message
        if response.status_code != 200:
            print(f"\nDEBUG ERROR: {response.json()}")

        assert response.status_code == 200
        data = response.json()
        
        assert data["metric"] == "weight"
        assert data["current"] == 15.5
        assert len(data["points"]) > 0
        assert "is_risk" in data
        assert "baseline" in data

@pytest.mark.asyncio
async def test_report_no_logs(db_session):
    """Checks that a 200 is returned with empty points if no logs exist."""
    # 1. SETUP: Create Owner, Species, Pet, and MetricDef (but NO logs)
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="no_logs@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    metric_def = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="Empty", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add_all([metric_def, pet])
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight")
        assert response.status_code == 200
        data = response.json()
        assert data["points"] == []
        assert "No logs" in data["message"]

@pytest.mark.asyncio
async def test_report_wrong_metric_for_species(db_session):
    """Ensures a 404 if the metric exists in the system but not for THIS species."""
    # 1. SETUP: Dog has 'weight', Cat has NO metrics
    dog_species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    cat_species = models.Species_config(species_name=models.SpeciesType.cat, breed_name="Tabby", notes="N")
    db_session.add_all([dog_species, cat_species])
    db_session.commit()

    # Metric defined ONLY for dog
    dog_metric = models.MetricDefinition(species_id=dog_species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="wrong_metric@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    db_session.add_all([dog_metric, owner])
    db_session.commit()

    # Create a CAT pet
    cat_pet = models.Pet(species_id=cat_species.species_id, owner_id=owner.owner_id, pet_first_name="Kitty", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add(cat_pet)
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Request 'weight' for the Cat (should be 404 because cat doesn't have weight defined)
        response = await ac.get(f"/reports/analysis/{cat_pet.pet_id}/weight")
        assert response.status_code == 404

@pytest.mark.asyncio
async def test_report_sorting_order(db_session):
    """Ensures points are returned by date, not by the order they were created."""
    # 1. SETUP: Basic pet/metric
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="sort@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    metric_def = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="Sorted", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add_all([metric_def, pet])
    db_session.commit()

    # 2. Add logs out of order (Tomorrow's log added BEFORE Yesterday's)
    tomorrow = datetime.utcnow() + timedelta(days=1)
    yesterday = datetime.utcnow() - timedelta(days=1)

    log1 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=20.0, metric_time=tomorrow)
    log2 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=10.0, metric_time=yesterday)
    
    db_session.add_all([log1, log2])
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight")
        points = response.json()["points"]
        
        # Verify chronological order: points[0] should be Yesterday (value 10.0)
        assert points[0]["y"] == 10.0
        assert points[1]["y"] == 20.0

@pytest.mark.asyncio
async def test_analysis_with_start_date_filter(db_session):
    """Ensures start_date parameter filters logs correctly."""
    # 1. SETUP: Create pet with metric
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="date_filter@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    metric_def = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="DateTest", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add_all([metric_def, pet])
    db_session.commit()

    # 2. Add logs on different dates
    base_time = datetime.utcnow()
    log1 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=10.0, metric_time=base_time - timedelta(days=5))
    log2 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=12.0, metric_time=base_time - timedelta(days=2))
    log3 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=15.0, metric_time=base_time)
    db_session.add_all([log1, log2, log3])
    db_session.commit()

    # 3. Query with start_date that filters out the oldest log
    start_date = (base_time - timedelta(days=3)).isoformat()
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight?start_date={start_date}")
        assert response.status_code == 200
        data = response.json()
        
        # Should only have log2 and log3
        assert len(data["points"]) == 2
        assert data["points"][0]["y"] == 12.0
        assert data["points"][1]["y"] == 15.0

@pytest.mark.asyncio
async def test_analysis_with_end_date_filter(db_session):
    """Ensures end_date parameter filters logs correctly."""
    # 1. SETUP: Create pet with metric
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="end_date@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    metric_def = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="EndDate", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add_all([metric_def, pet])
    db_session.commit()

    # 2. Add logs on different dates
    base_time = datetime.utcnow()
    log1 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=10.0, metric_time=base_time - timedelta(days=5))
    log2 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=12.0, metric_time=base_time - timedelta(days=2))
    log3 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=15.0, metric_time=base_time)
    db_session.add_all([log1, log2, log3])
    db_session.commit()

    # 3. Query with end_date that filters out the newest log
    end_date = (base_time - timedelta(days=1)).isoformat()
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight?end_date={end_date}")
        assert response.status_code == 200
        data = response.json()
        
        # Should only have log1 and log2
        assert len(data["points"]) == 2
        assert data["points"][0]["y"] == 10.0
        assert data["points"][1]["y"] == 12.0

@pytest.mark.asyncio
async def test_analysis_with_date_range_filter(db_session):
    """Ensures both start_date and end_date work together."""
    # 1. SETUP: Create pet with metric
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="date_range@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    metric_def = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="Range", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add_all([metric_def, pet])
    db_session.commit()

    # 2. Add logs on different dates
    base_time = datetime.utcnow()
    log1 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=10.0, metric_time=base_time - timedelta(days=10))
    log2 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=12.0, metric_time=base_time - timedelta(days=5))
    log3 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def.metric_def_id, metric_value=15.0, metric_time=base_time)
    db_session.add_all([log1, log2, log3])
    db_session.commit()

    # 3. Query with date range that captures only log2
    start_date = (base_time - timedelta(days=7)).isoformat()
    end_date = (base_time - timedelta(days=3)).isoformat()
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight?start_date={start_date}&end_date={end_date}")
        assert response.status_code == 200
        data = response.json()
        
        # Should only have log2
        assert len(data["points"]) == 1
        assert data["points"][0]["y"] == 12.0

@pytest.mark.asyncio
async def test_analysis_invalid_start_date_format(db_session):
    """Ensures 400 error for invalid start_date format."""
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="invalid_date@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    metric_def = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="BadDate", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add_all([metric_def, pet])
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/analysis/{pet.pet_id}/weight?start_date=invalid-date")
        assert response.status_code == 400
        assert "ISO format" in response.json()["detail"]

@pytest.mark.asyncio
async def test_get_logged_metrics_success(db_session):
    """Ensures logged-metrics endpoint returns list of metric names for a pet."""
    # 1. SETUP: Create pet with multiple metrics logged
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="logged_metrics@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    metric_def_weight = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.weight, metric_unit=models.MetricUnit.kg)
    metric_def_water = models.MetricDefinition(species_id=species.species_id, metric_name=models.MetricName.water_intake, metric_unit=models.MetricUnit.ml)
    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="Multi", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add_all([metric_def_weight, metric_def_water, pet])
    db_session.commit()

    # 2. Add logs for both metrics
    log1 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def_weight.metric_def_id, metric_value=15.0, metric_time=datetime.utcnow())
    log2 = models.HealthMetric(pet_id=pet.pet_id, metric_def_id=metric_def_water.metric_def_id, metric_value=500.0, metric_time=datetime.utcnow())
    db_session.add_all([log1, log2])
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/logged-metrics/{pet.pet_id}")
        assert response.status_code == 200
        metrics = response.json()
        
        # Should return both metric names
        assert len(metrics) == 2
        assert "weight" in metrics
        assert "water_intake" in metrics

@pytest.mark.asyncio
async def test_get_logged_metrics_empty(db_session):
    """Ensures logged-metrics returns empty list for pet with no logs."""
    # 1. SETUP: Create pet without any logs
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="empty_metrics@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="NoLogs", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add(pet)
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/logged-metrics/{pet.pet_id}")
        assert response.status_code == 200
        metrics = response.json()
        
        # Should return empty list
        assert metrics == []

@pytest.mark.asyncio
async def test_get_logged_metrics_nonexistent_pet(db_session):
    """Ensures logged-metrics returns empty list for nonexistent pet (no error)."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/reports/logged-metrics/9999")
        assert response.status_code == 200
        metrics = response.json()
        assert metrics == []

@pytest.mark.asyncio
async def test_get_report_history_nonexistent_pet(db_session):
    """Ensures history endpoint returns 404 for nonexistent pet."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/reports/history/9999")
        assert response.status_code == 404

@pytest.mark.asyncio
async def test_get_report_history_empty(db_session):
    """Ensures history endpoint returns empty list for pet with no reports."""
    # 1. SETUP: Create pet without any reports
    owner = models.Owner(owner_first_name="L", owner_last_name="C", owner_email="empty_history@test.com", 
                         owner_phone_number=str(uuid.uuid4()), owner_address1="S", owner_postcode="P", owner_city="C")
    species = models.Species_config(species_name=models.SpeciesType.dog, breed_name="Lab", notes="N")
    db_session.add_all([owner, species])
    db_session.commit()

    pet = models.Pet(species_id=species.species_id, owner_id=owner.owner_id, pet_first_name="HistoryEmpty", pet_address1="S", pet_postcode="P", pet_city="C")
    db_session.add(pet)
    db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get(f"/reports/history/{pet.pet_id}")
        assert response.status_code == 200
        reports = response.json()
        assert reports == []

@pytest.mark.asyncio
async def test_get_report_detail_nonexistent_report(db_session):
    """Ensures detail endpoint returns 404 for nonexistent report."""
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/reports/detail/9999")
        assert response.status_code == 404