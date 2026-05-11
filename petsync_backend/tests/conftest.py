import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from petsync_backend.database import Base, get_db
from petsync_backend.utils.auth_utils import get_current_owner_id
from petsync_backend.tests._test_state import _current_test_owner_id
from petsync_backend.main import app
import os

SQLALCHEMY_DATABASE_URL = "sqlite:///./test_temp.db"


@pytest.fixture(scope="session", autouse=True)
def setup_database():
    engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield engine

import gc
gc.collect()
try:
    if os.path.exists("./test_temp.db"):
        os.remove("./test_temp.db")
except PermissionError:
    pass


@pytest.fixture
def db_session(setup_database):
    engine = setup_database
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture(autouse=True)
def override_get_db(db_session):
    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    app.dependency_overrides[get_current_owner_id] = lambda: _current_test_owner_id[0] or 0
    yield
    app.dependency_overrides.clear()
    _current_test_owner_id[0] = None
