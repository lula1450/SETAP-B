from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import timedelta
import bcrypt

from petsync_backend.database import get_db
from petsync_backend import models, schemas
from petsync_backend.routers.owners import DELETION_GRACE_DAYS
from petsync_backend.utils.auth_utils import create_access_token

router = APIRouter(prefix="", tags=["Auth"])


def _hash_password(plain: str) -> str:
    """Hashes a plain-text password using bcrypt. Returns the hashed string."""
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def _verify_password(plain: str, hashed: str) -> bool:
    """Checks a plain-text password against a stored bcrypt hash. Returns False on mismatch or malformed hash."""
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except ValueError:
        return False


@router.post("/login")
def login(details: schemas.LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticates an owner and returns a JWT access token.

    Returns owner profile fields alongside the token. If account deletion has been
    requested, status becomes 'pending_deletion' and the scheduled purge date is included.
    Raises 401 if credentials are invalid.
    """
    owner = db.query(models.Owner).filter(models.Owner.owner_email == details.email).first()

    if not owner or not _verify_password(details.password, owner.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    response = {
        "status": "success",
        "token": create_access_token(owner.owner_id),
        "owner_id": owner.owner_id,
        "owner_email": owner.owner_email,
        "owner_first_name": owner.owner_first_name,
        "owner_last_name": owner.owner_last_name,
        "deletion_requested_at": None,
    }
    if owner.deletion_requested_at:
        purge_at = owner.deletion_requested_at + timedelta(days=DELETION_GRACE_DAYS)
        response["deletion_requested_at"] = owner.deletion_requested_at.isoformat()
        response["scheduled_purge_at"] = purge_at.isoformat()
        response["status"] = "pending_deletion"
    return response


@router.post("/signup")
def signup(owner: schemas.OwnerCreate, db: Session = Depends(get_db)):
    """
    Registers a new owner account and returns a JWT access token.

    Raises 400 if the email address is already in use.
    """
    existing_user = db.query(models.Owner).filter(models.Owner.owner_email == owner.owner_email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_owner = models.Owner(
        owner_first_name=owner.owner_first_name,
        owner_last_name=owner.owner_last_name,
        owner_email=owner.owner_email,
        password=_hash_password(owner.password),
    )
    db.add(new_owner)
    db.commit()
    db.refresh(new_owner)

    return {
        "status": "success",
        "token": create_access_token(new_owner.owner_id),
        "owner_id": new_owner.owner_id,
        "owner_email": new_owner.owner_email,
        "owner_first_name": new_owner.owner_first_name,
        "owner_last_name": new_owner.owner_last_name,
    }
