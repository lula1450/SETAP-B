import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from petsync_backend.database import Base, get_db
from petsync_backend.main import app
from petsync_backend.models import (
    HealthMetric, MetricDefinition, MetricName, 
    MetricUnit, Species_config, SpeciesType
)

# -----------------------------
# Setup Persistent In-memory SQLite DB
# -----------------------------
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    connect_args={"check_same_thread": False}, # Fixed duplicate key here
    poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    # Temporarily OFF to allow tests to run without creating Pet/Owner records
    cursor.execute("PRAGMA foreign_keys=OFF") 
    cursor.close()

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

# -----------------------------
# Fixture for setup
# -----------------------------
@pytest.fixture(scope="module")
def setup_metrics():
    # 1. Create tables
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()

    try:
        # 2. Create Species record
        test_species = Species_config(
            species_name=SpeciesType.dog,
            breed_name="Golden Retriever",
            notes="Test species"
        )
        db.add(test_species)
        db.commit()
        db.refresh(test_species)

        # 3. Create all required Metric Definitions
        metrics = [
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.weight, metric_unit=MetricUnit.kg),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.water_intake, metric_unit=MetricUnit.ml),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.energy_level, metric_unit=MetricUnit.scale_1_5),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.vomit_events, metric_unit=MetricUnit.scale_1_5),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.appetite, metric_unit=MetricUnit.scale_1_5),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.basking_time, metric_unit=MetricUnit.kg),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.wheel_activity, metric_unit=MetricUnit.scale_1_5),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.humidity_level, metric_unit=MetricUnit.kg),
            MetricDefinition(species_id=test_species.species_id, metric_name=MetricName.notes, metric_unit=MetricUnit.text),
        ]
        db.add_all(metrics)
        db.commit()

        yield db # Data is now ready for tests

    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

# -----------------------------
# Test Cases
# -----------------------------
def test_log_health_metric(setup_metrics):
    payload = {"pet_id": 1, "metric_name": "weight", "value": 4.5, "notes": "Pet is doing well"}
    response = client.post("/health/log", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Logged"

def test_weight_alert(setup_metrics):
    # Log first weight
    client.post("/health/log", json={"pet_id": 2, "metric_name": "weight", "value": 4.0})
    # Log second weight (25% increase)
    response = client.post("/health/log", json={"pet_id": 2, "metric_name": "weight", "value": 5.0})
    data = response.json()
    assert "ALERT" in data["analysis"]

def test_text_metric_alert(setup_metrics):
    payload = {"pet_id": 3, "metric_name": "notes", "value": "Pet seems lethargic", "notes": ""}
    response = client.post("/health/log", json=payload)
    data = response.json()
    assert "ALERT" in data["analysis"]

def test_non_numeric_metric(setup_metrics):
    payload = {"pet_id": 4, "metric_name": "weight", "value": "not_a_number", "notes": ""}
    response = client.post("/health/log", json=payload)
    data = response.json()
    assert "ERROR" in data["analysis"]