from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from petsync_backend import models, schemas, database

router = APIRouter(
    prefix="/owners",
    tags=["owners"]
)

@router.post("/", response_model=schemas.OwnerResponse, status_code=201)
def create_owner(owner: schemas.OwnerCreate, db: Session = Depends(database.get_db)):
    # Check if email already exists
    db_owner = db.query(models.Owner).filter(models.Owner.owner_email == owner.owner_email).first()
    if db_owner:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_owner = models.Owner(**owner.model_dump())
    db.add(new_owner)
    db.commit()
    db.refresh(new_owner)
    return new_owner

@router.get("/{owner_id}", response_model=schemas.OwnerResponse)
def get_owner(owner_id: int, db: Session = Depends(database.get_db)):
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    return owner

@router.delete("/{owner_id}")
def delete_owner(owner_id: int, db: Session = Depends(database.get_db)):
    # 1. Find the owner
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    # 2. Delete the owner (SQLAlchemy handles the rest if cascade is set)
    db.delete(owner)
    db.commit()
    
    return {"message": f"Owner {owner_id} and all associated data deleted successfully"}