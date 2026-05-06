from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import bcrypt

from petsync_backend.database import get_db
from petsync_backend import models, schemas

router = APIRouter(prefix="", tags=["Auth"])


def _hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def _verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


@router.post("/login")
def login(details: schemas.LoginRequest, db: Session = Depends(get_db)):
    owner = db.query(models.Owner).filter(models.Owner.owner_email == details.email).first()

    if not owner or not _verify_password(details.password, owner.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return {
        "status": "success",
        "owner_id": owner.owner_id,
        "owner_email": owner.owner_email,
        "owner_first_name": owner.owner_first_name,
        "owner_last_name": owner.owner_last_name,
    }


@router.post("/signup")
def signup(owner: schemas.OwnerCreate, db: Session = Depends(get_db)):
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
        "owner_id": new_owner.owner_id,
        "owner_email": new_owner.owner_email,
        "owner_first_name": new_owner.owner_first_name,
        "owner_last_name": new_owner.owner_last_name,
    }
