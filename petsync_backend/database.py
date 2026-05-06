#File is created to bridge the gap between the API and our database
# provides the get_db() dependency so we can safely query and commit data
# without duplicating connection logic

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
# petsync_backend/database.py

from petsync_backend.models import Base

# Define the database URL and create the SQLAlchemy engine for connecting to the database.
#  In this case, we are using SQLite for simplicity (and so we dont need login credentials), 
# but this can be replaced with any other database URL as needed.
DATABASE_URL = "sqlite:///./petsync.db"

# Create the SQLAlchemy engine and session factory for database interactions.
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)

# Create session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Dependency used in routers
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Optional: automatically create tables
Base.metadata.create_all(bind=engine)

# Add deletion_requested_at column if it doesn't exist yet (safe for existing DBs)
from sqlalchemy import text as _text
try:
    with engine.connect() as _conn:
        _conn.execute(_text("ALTER TABLE owner ADD COLUMN deletion_requested_at DATETIME"))
        _conn.commit()
except Exception:
    pass  # column already exists
