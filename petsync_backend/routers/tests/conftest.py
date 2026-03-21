import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from petsync_backend.database import Base, get_db
from petsync_backend.main import app
import os

# Use a clean file for every test session
SQLALCHEMY_DATABASE_URL = "sqlite:///./test_temp.db"

@pytest.fixture(scope="session", autouse=True)
def setup_database():
    # 1. Create the engine
    engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
    
    # 2. Force the tables to be created (Fixes 'no such table' error)
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    yield engine
    
    # 3. Cleanup
    if os.path.exists("./test_temp.db"):
        os.remove("./test_temp.db")

@pytest.fixture
def db_session(setup_database):
    engine = setup_database
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

# This tells FastAPI to use our test database instead of the real one during tests
@pytest.fixture(autouse=True)
def override_get_db(db_session):
    def _override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = _override_get_db
    yield
    app.dependency_overrides.clear()