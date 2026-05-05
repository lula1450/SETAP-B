from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from petsync_backend import models, schemas, database

router = APIRouter()

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
        # Delete Pet Metadata
        db.query(models.PetMetaData).filter(
            models.PetMetaData.pet_id == pet.pet_id
        ).delete()
        
        # Delete Pet Goals
        db.query(models.PetGoal).filter(
            models.PetGoal.pet_id == pet.pet_id
        ).delete()
        
        # Delete Feeding Schedules (and their associated reminders first)
        feeding_schedules = db.query(models.FeedingSchedule).filter(
            models.FeedingSchedule.pet_id == pet.pet_id
        ).all()
        for schedule in feeding_schedules:
            db.query(models.Reminder).filter(
                models.Reminder.feeding_schedule_id == schedule.feeding_schedule_id
            ).delete()
        db.query(models.FeedingSchedule).filter(
            models.FeedingSchedule.pet_id == pet.pet_id
        ).delete()
        
        # Delete Pet Appointments (and their associated reminders first)
        appointments = db.query(models.PetAppointment).filter(
            models.PetAppointment.pet_id == pet.pet_id
        ).all()
        for appointment in appointments:
            db.query(models.Reminder).filter(
                models.Reminder.pet_appointment_id == appointment.pet_appointment_id
            ).delete()
        db.query(models.PetAppointment).filter(
            models.PetAppointment.pet_id == pet.pet_id
        ).delete()
        
        # Delete Health Metrics
        db.query(models.HealthMetric).filter(
            models.HealthMetric.pet_id == pet.pet_id
        ).delete()
        
        # Delete Pet Reports
        db.query(models.PetReport).filter(
            models.PetReport.pet_id == pet.pet_id
        ).delete()
        
        # Delete pet
        db.delete(pet)

    # 2. Delete the owner 
    db.delete(owner)
    db.commit()
    
    return {"message": f"Owner {owner_id} and all associated data deleted successfully"}

@router.put("/{owner_id}", response_model=schemas.OwnerResponse)
async def update_owner(owner_id: int, owner_data: schemas.OwnerUpdate, db: Session = Depends(database.get_db)):
    print(f"\n{'='*60}")
    print(f"DEBUG: update_owner called with owner_id={owner_id}")
    print(f"DEBUG: owner_data={owner_data}")
    print(f"{'='*60}\n")
    
    db_owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    print(f"DEBUG: Query result for owner_id {owner_id}: {db_owner}")
    
    if not db_owner:
        # Debug: List all owners in the database
        all_owners = db.query(models.Owner).all()
        print(f"DEBUG: All owners in database: {[(o.owner_id, o.owner_email) for o in all_owners]}")
        raise HTTPException(status_code=404, detail="Owner not found")

    # Update only the fields provided in the request (excluding None values)
    update_data = owner_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if value is not None and hasattr(db_owner, key):
            print(f"DEBUG: Setting {key} = {value}")
            setattr(db_owner, key, value)
    
    db.commit()
    db.refresh(db_owner)
    print(f"DEBUG: Owner updated successfully: {db_owner}")
    return db_owner