# Bridges the API and the SQLite database.
# Provides the get_db() dependency so routers can safely query and commit
# without duplicating connection logic.

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

from petsync_backend.models import Base

DATABASE_URL = "sqlite:///./petsync.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False, "timeout": 30}
)

# Enable WAL mode and a busy timeout to reduce write contention on SQLite.
@event.listens_for(engine, "connect")
def set_sqlite_pragmas(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA journal_mode=WAL")
    cursor.execute("PRAGMA busy_timeout=5000")
    cursor.close()

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

def get_db():
    """FastAPI dependency that yields a DB session and closes it on exit."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

Base.metadata.create_all(bind=engine)

# Adds deletion_requested_at to the owner table for existing databases that
# predate this column. The ALTER TABLE is a no-op if the column already exists.
from sqlalchemy import text as _text
try:
    with engine.connect() as _conn:
        _conn.execute(_text("ALTER TABLE owner ADD COLUMN deletion_requested_at DATETIME"))
        _conn.commit()
except Exception:
    pass
