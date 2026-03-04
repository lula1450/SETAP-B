import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from petsync_backend.main import app
from petsync_backend.database import get_db
from petsync_backend.models import Base


def test_create_appointment():
    # Create in-memory test database
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine)

    # Create tables
    Base.metadata.create_all(bind=engine)

    # Override dependency
    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    client = TestClient(app)

    # 🔥 Create required pet first (prevents FK errors)
    pet_response = client.post("/pets", json={
        "name": "Buddy",
        "species": "Dog",
        "age": 3
    })
    assert pet_response.status_code in (200, 201)

    # Now create appointment
    response = client.post("/schedule/appointments", json={
        "pet_id": 1,
        "appointment_date": "2026-05-01",
        "appointment_time": "10:00:00"
    })

    print(response.status_code)
    print(response.json())

    assert response.status_code == 201

    # Cleanup
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)