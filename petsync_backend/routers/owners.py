from fastapi import APIRouter, Depends, HTTPException, Body
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

#deletes app/metrics/pet with the owner
@router.delete("/{owner_id}")
def delete_owner(owner_id: int, db: Session = Depends(database.get_db)):
    # 1. Find the owner
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    
    pets = db.query(models.Pet).filter(models.Pet.owner_id == owner_id).all()

    for pet in pets:
        #Deletes Pet Appointment
        db.query(models.PetAppointment).filter(
            models.PetAppointment.pet_id == pet.pet_id
        ).delete()
        #Delete Health Metrics
        db.query(models.HealthMetric).filter(
            models.HealthMetric.pet_id == pet.pet_id
        ).delete()
        #Deletes pet
        db.delete(pet)

    # 2. Delete the owner 
    db.delete(owner)
    db.commit()
    
    return {"message": f"Owner {owner_id} and all associated data deleted successfully"}

@router.put("/{owner_id}", response_model=schemas.OwnerResponse)
async def update_owner(owner_id: int, owner_data: dict = Body(...), db: Session = Depends(database.get_db)):
    db_owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not db_owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    # Update only the fields provided in the request
    for key, value in owner_data.items():
        if hasattr(db_owner, key):
            setattr(db_owner, key, value)
    
    db.commit()
    db.refresh(db_owner)
    return db_owner