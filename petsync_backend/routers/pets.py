from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from petsync_backend import models, schemas
from petsync_backend.database import get_db
from datetime import datetime  # Add this import at the top



router = APIRouter()



@router.put("/appointments/{appointment_id}")
async def update_appointment(
    appointment_id: int, 
    data: dict, 
    db: Session = Depends(get_db)
):
    appt = db.query(models.PetAppointment).filter(
        models.PetAppointment.pet_appointment_id == appointment_id
    ).first()

    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")

    # Handle the time conversion
    time_str = data.get("pet_appointment_time")
    if time_str:
        try:
            # Convert "18:30:00" string into a Python time object
            appt.pet_appointment_time = datetime.strptime(time_str, "%H:%M:%S").time()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid time format. Use HH:MM:SS")

    # Update notes (this is a string, so no conversion needed)
    appt.appointment_notes = data.get("appointment_notes", appt.appointment_notes)

    db.commit()
    return {"message": "Update successful"}

@router.delete("/appointments/{appointment_id}")
def delete_appointment(appointment_id: int, db: Session = Depends(get_db)):
    appt = db.query(models.PetAppointment).filter(models.PetAppointment.pet_appointment_id == appointment_id).first()
    
    if not appt:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    db.delete(appt)
    db.commit()
    return {"message": "Successfully deleted"}



# Create a pet profile
# Create a pet profile
@router.post("/create", response_model=schemas.PetResponse) # Changed from "/" to "/create"
def create_pet(pet: schemas.PetCreate, db: Session = Depends(get_db)):
    owner = db.query(models.Owner).filter(models.Owner.owner_id == pet.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    db_pet = models.Pet(
        species_id=pet.species_id,
        owner_id=pet.owner_id,
        pet_first_name=pet.pet_first_name,
        # If the frontend sends an empty string or null, this stays clean
        pet_last_name=pet.pet_last_name or "", 
        pet_address1=pet.pet_address1,
        pet_address2=pet.pet_address2,
        pet_postcode=pet.pet_postcode,
        pet_city=pet.pet_city,
    )

    db.add(db_pet)
    db.commit()
    db.refresh(db_pet)
    
    # Rest of the return logic stays the same...
    return schemas.PetResponse(
        pet_id=db_pet.pet_id,
        species_id=db_pet.species_id,
        owner_id=db_pet.owner_id,
        pet_first_name=db_pet.pet_first_name,
        pet_last_name=db_pet.pet_last_name,
        pet_address1=db_pet.pet_address1,
        pet_address2=db_pet.pet_address2,
        pet_postcode=db_pet.pet_postcode,
        pet_city=db_pet.pet_city,
        pet_image_path=db_pet.pet_image_path,
    )


# Get a single pet with its species info
@router.get("/{pet_id}", response_model=schemas.PetResponse)
def get_pet(pet_id: int, db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")

    species = db.query(models.Species_config).filter(
        models.Species_config.species_id == pet.species_id
    ).first()
    
    # SAFETY CHECK: If species is None, don't crash, just say "Unknown"
    species_name = species.species_name if species else "Unknown"

    return schemas.PetResponse(
        pet_id=pet.pet_id,
        pet_first_name=pet.pet_first_name,
        pet_last_name=pet.pet_last_name,
        pet_address1=pet.pet_address1,
        pet_city=pet.pet_city,
        species_name=species_name,
        owner_id=pet.owner_id,
        species_id=pet.species_id,
        pet_image_path=pet.pet_image_path,
    )


# 3️⃣ List all the owner's pets
@router.get("/owner/{owner_id}", response_model=list[schemas.PetResponse])
def list_all_pets(owner_id: int, db: Session = Depends(get_db)):
    pets = db.query(models.Pet).filter(models.Pet.owner_id == owner_id).all()
    if not pets:
        raise HTTPException(status_code=404, detail="No pets found for this owner")

    # Pre-fetch species info to avoid repeated queries
    species_map = {
        s.species_id: s.species_name
        for s in db.query(models.Species_config).all()
    }

    return [
        schemas.PetResponse(
            pet_id=pet.pet_id,
            pet_first_name=pet.pet_first_name,
            pet_last_name=pet.pet_last_name,
            pet_address1=pet.pet_address1,
            pet_address2=pet.pet_address2,
            pet_city=pet.pet_city,
            species_name=species_map.get(pet.species_id, "Unknown"),
            owner_id=pet.owner_id,
            species_id=pet.species_id,
            pet_image_path=pet.pet_image_path,
        )
        for pet in pets
    ]

# Update pet profile
@router.put("/{pet_id}", response_model=schemas.PetResponse)
def update_pet(pet_id: int, pet_update: schemas.PetCreate, db: Session = Depends(get_db)):
    db_pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not db_pet:
        raise HTTPException(status_code=404, detail="Pet not found")

    # Update fields
    db_pet.pet_first_name = pet_update.pet_first_name
    db_pet.pet_last_name = pet_update.pet_last_name
    db_pet.pet_address1 = pet_update.pet_address1
    db_pet.pet_city = pet_update.pet_city
    # Note: species_id and owner_id usually don't change, so we leave them

    db.commit()
    db.refresh(db_pet)
    return db_pet

# petsync_backend/routers/pets.py

@router.delete("/{pet_id}")
def delete_pet(pet_id: int, db: Session = Depends(get_db)):
    db_pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not db_pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    
    db.delete(db_pet)
    db.commit()
    return {"message": f"Pet {pet_id} and all associated data deleted successfully"}

# In your FastAPI backend (e.g., main.py or routers/pets.py)
# petsync_backend/routers/pets.py (or main.py)

# petsync_backend/routers/pets.py (or main.py)

@router.put("/{pet_id}/image")
async def update_pet_image(pet_id: int, image_url: str, db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    pet.pet_image_path = image_url
    db.commit()
    return {"message": "Image updated"}

