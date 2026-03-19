"""from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from petsync_backend import models, schemas
from petsync_backend.database import get_db



router = APIRouter()


# Create a pet profile
@router.post("/", response_model=schemas.PetResponse)
def create_pet(pet: schemas.PetCreate, db: Session = Depends(get_db)):
    """
   # Create pet profile with species-specific data.
   # Checks if the owner exists before creating the pet.
"""
    owner = db.query(models.User).filter(models.User.user_id == pet.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    db_pet = models.Pet(
        species_id=pet.species_id,
        owner_id=pet.owner_id,
        pet_first_name=pet.pet_first_name,
        pet_last_name=pet.pet_last_name,
        pet_address1=pet.pet_address1,
        pet_address2=pet.pet_address2,
        pet_city=pet.pet_city,
    )

    db.add(db_pet)
    db.commit()
    db.refresh(db_pet)

    return schemas.PetResponse(
        pet_id=db_pet.pet_id,
        species_id=db_pet.species_id,
        owner_id=db_pet.owner_id,
        pet_first_name=db_pet.pet_first_name,
        pet_last_name=db_pet.pet_last_name,
        pet_address1=db_pet.pet_address1,
        pet_address2=db_pet.pet_address2,
        pet_city=db_pet.pet_city,
    )


# Get a single pet with its species info
@router.get("/{pet_id}", response_model=schemas.PetResponse)
def get_pet(pet_id: int, db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")

    species = db.query(models.SpeciesConfig).filter(models.SpeciesConfig.species_id == pet.species_id).first()
    species_name = species.species_name if species else "Unknown"

    return schemas.PetResponse(
        pet_id=pet.pet_id,
        pet_first_name=pet.pet_first_name,
        pet_last_name=pet.pet_last_name,
        pet_address1=pet.pet_address1,
        pet_address2=pet.pet_address2,
        pet_city=pet.pet_city,
        species_name=species_name,
        owner_id=pet.owner_id,
        species_id=pet.species_id,
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
        for s in db.query(models.SpeciesConfig).all()
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
        )
        for pet in pets
    ]

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from petsync_backend import models, schemas
from petsync_backend.database import get_db

router = APIRouter()


# 1️⃣ Create a pet profile
@router.post("/", response_model=schemas.PetResponse)
def create_pet(pet: schemas.PetCreate, db: Session = Depends(get_db)):
    """
    #Create pet profile with species-specific data.
    #Checks if the owner exists before creating the pet.
"""
    owner = db.query(models.User).filter(models.User.user_id == pet.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    db_pet = models.Pet(
        species_id=pet.species_id,
        owner_id=pet.owner_id,
        pet_first_name=pet.pet_first_name,
        pet_last_name=pet.pet_last_name,
        pet_address1=pet.pet_address1,
        pet_address2=pet.pet_address2,
        pet_city=pet.pet_city,
    )

    db.add(db_pet)
    db.commit()
    db.refresh(db_pet)

    return schemas.PetResponse(
        pet_id=db_pet.pet_id,
        species_id=db_pet.species_id,
        owner_id=db_pet.owner_id,
        pet_first_name=db_pet.pet_first_name,
        pet_last_name=db_pet.pet_last_name,
        pet_address1=db_pet.pet_address1,
        pet_address2=db_pet.pet_address2,
        pet_city=db_pet.pet_city,
    )


# 2️⃣ Get a single pet with its species info
@router.get("/{pet_id}", response_model=schemas.PetResponse)
def get_pet(pet_id: int, db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")

    species = db.query(models.SpeciesConfig).filter(models.SpeciesConfig.species_id == pet.species_id).first()
    species_name = species.species_name if species else "Unknown"

    return schemas.PetResponse(
        pet_id=pet.pet_id,
        pet_first_name=pet.pet_first_name,
        pet_last_name=pet.pet_last_name,
        pet_address1=pet.pet_address1,
        pet_address2=pet.pet_address2,
        pet_city=pet.pet_city,
        species_name=species_name,
        owner_id=pet.owner_id,
        species_id=pet.species_id,
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
        for s in db.query(models.SpeciesConfig).all()
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
        )
        for pet in pets
    ]

"""