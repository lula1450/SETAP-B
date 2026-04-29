from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

# Import the database connection
from petsync_backend.database import get_db

# Import the modules so you can use models.Owner and schemas.OwnerCreate
from petsync_backend import models, schemas

router = APIRouter(prefix="", tags=["Auth"])

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(details: LoginRequest, db: Session = Depends(get_db)):
    # Use the 'models' prefix consistently
    owner = db.query(models.Owner).filter(models.Owner.owner_email == details.email).first()
    
    if not owner:
        raise HTTPException(status_code=404, detail="User not found")
    
    if owner.password != details.password:
        raise HTTPException(status_code=401, detail="Incorrect password")
    
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
        password=owner.password,
    )
    db.add(new_owner)
    db.commit()
    db.refresh(new_owner)
    
    # Crucial: Return the full owner object so Flutter can save the owner_id
    return new_owner
