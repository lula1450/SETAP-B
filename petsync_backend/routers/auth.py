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