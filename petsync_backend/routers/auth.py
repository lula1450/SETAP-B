from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from petsync_backend.database import get_db
from petsync_backend.models import Owner
from pydantic import BaseModel

router = APIRouter(prefix="", tags=["Auth"])

class LoginRequest(BaseModel):
    email: str
    password: str # In a real app, we would hash this!

@router.post("/login")
def login(details: LoginRequest, db: Session = Depends(get_db)):
    owner = db.query(Owner).filter(Owner.owner_email == details.email).first()
    
    if not owner:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check the password
    if owner.password != details.password:
        raise HTTPException(status_code=401, detail="Incorrect password")
    
    return {
        "status": "success",
        "owner_id": owner.owner_id,
        "first_name": owner.owner_first_name
    }

# petsync_backend/routers/auth.py

@router.post("/signup", response_model=schemas.OwnerResponse)
def signup(owner: schemas.OwnerCreate, db: Session = Depends(get_db)):
    # 1. Check if email already exists
    existing_user = db.query(models.Owner).filter(models.Owner.owner_email == owner.owner_email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    # 2. Create the new owner object
    new_owner = models.Owner(
        owner_first_name=owner.owner_first_name,
        owner_last_name=owner.owner_last_name,
        owner_email=owner.owner_email,
        password=owner.password, # In a real app, you'd hash this!
        owner_phone=owner.owner_phone
    )

    db.add(new_owner)
    db.commit()
    db.refresh(new_owner)
    return new_owner