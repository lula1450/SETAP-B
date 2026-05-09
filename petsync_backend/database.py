#File is created to bridge the gap between the API and our database
# provides the get_db() dependency so we can safely query and commit data
# without duplicating connection logic

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
# petsync_backend/database.py

from petsync_backend.models import Base

DATABASE_URL = "sqlite:///./petsync.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False, "timeout": 30}
)

@event.listens_for(engine, "connect")
def set_sqlite_pragmas(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA journal_mode=WAL")
    cursor.execute("PRAGMA busy_timeout=5000")
    cursor.close()

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
