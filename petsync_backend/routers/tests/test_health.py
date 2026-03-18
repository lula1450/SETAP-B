# tests/test_health.py

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from petsync_backend.database import Base, get_db
from petsync_backend.main import app
from petsync_backend.models import HealthMetric, MetricDefinition, MetricName, MetricUnit

# -----------------------------
# Setup in-memory SQLite DB
# -----------------------------
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Override get_db dependency to use in-memory DB
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

# Create tables
Base.metadata.create_all(bind=engine)

# Test client
client = TestClient(app)

# -----------------------------
# Fixtures for metric setup
# -----------------------------
@pytest.fixture(scope="module")
def setup_metrics():
    db = TestingSessionLocal()
    metrics = [
        MetricDefinition(metric_name=MetricName.weight, metric_unit=MetricUnit.kg),
        MetricDefinition(metric_name=MetricName.water_intake, metric_unit=MetricUnit.ml),
        MetricDefinition(metric_name=MetricName.energy_level, metric_unit=MetricUnit.scale_1_5),
        MetricDefinition(metric_name=MetricName.vomit_events, metric_unit=MetricUnit.scale_1_5),
        MetricDefinition(metric_name=MetricName.appetite, metric_unit=MetricUnit.scale_1_5),
        MetricDefinition(metric_name=MetricName.basking_time, metric_unit=MetricUnit.kg),
        MetricDefinition(metric_name=MetricName.wheel_activity, metric_unit=MetricUnit.scale_1_5),
        MetricDefinition(metric_name=MetricName.humidity_level, metric_unit=MetricUnit.kg),
        MetricDefinition(metric_name=MetricName.notes, metric_unit=MetricUnit.text),
    ]
    db.add_all(metrics)
    db.commit()
    db.close()

# -----------------------------
# Test Cases
# -----------------------------
def test_log_health_metric(setup_metrics):
    payload = {"pet_id": 1, "metric_name": "weight", "value": 4.5, "notes": "Pet is doing well"}
    response = client.post("/health/log", json=payload)
    data = response.json()
    assert response.status_code == 200
    assert data["status"] == "Logged"
    assert "analysis" in data

def test_weight_alert(setup_metrics):
    client.post("/health/log", json={"pet_id": 2, "metric_name": "weight", "value": 4.0})
    response = client.post("/health/log", json={"pet_id": 2, "metric_name": "weight", "value": 5.0})
    data = response.json()
    assert "ALERT" in data["analysis"]

def test_text_metric_alert(setup_metrics):
    payload = {"pet_id": 3, "metric_name": "notes", "value": "Pet seems lethargic and has diarrhea", "notes": ""}
    response = client.post("/health/log", json=payload)
    data = response.json()
    assert "ALERT" in data["analysis"]

def test_non_numeric_metric(setup_metrics):
    payload = {"pet_id": 4, "metric_name": "weight", "value": "not_a_number", "notes": ""}
    response = client.post("/health/log", json=payload)
    data = response.json()
    assert "ERROR" in data["analysis"]