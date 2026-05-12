from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from petsync_backend import models, schemas
from petsync_backend.database import get_db
from petsync_backend.utils.auth_utils import get_current_owner_id

router = APIRouter()


@router.post("/create", response_model=schemas.PetResponse)
def create_pet(pet: schemas.PetCreate, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(get_db)):
    if current_owner_id != pet.owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    owner = db.query(models.Owner).filter(models.Owner.owner_id == pet.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    db_pet = models.Pet(
        species_id=pet.species_id,
        owner_id=pet.owner_id,
        pet_first_name=pet.pet_first_name,
        pet_last_name=pet.pet_last_name or "",
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
        pet_image_path=db_pet.pet_image_path,
    )


@router.get("/{pet_id}", response_model=schemas.PetResponse)
def get_pet(pet_id: int, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    if pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    species = db.query(models.Species_config).filter(
        models.Species_config.species_id == pet.species_id
    ).first()
    species_name = species.species_name if species else "Unknown"

    return schemas.PetResponse(
        pet_id=pet.pet_id,
        pet_first_name=pet.pet_first_name,
        pet_last_name=pet.pet_last_name,
        species_name=species_name,
        owner_id=pet.owner_id,
        species_id=pet.species_id,
        pet_image_path=pet.pet_image_path,
    )


@router.get("/owner/{owner_id}", response_model=list[schemas.PetResponse])
def list_all_pets(owner_id: int, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(get_db)):
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    if current_owner_id != owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    pets = db.query(models.Pet).filter(models.Pet.owner_id == owner_id).all()
    if not pets:
        raise HTTPException(status_code=404, detail="No pets found for this owner")

    # Pre-fetch all species in one query to avoid N+1 lookups per pet
    species_map = {
        s.species_id: s.species_name
        for s in db.query(models.Species_config).all()
    }

    return [
        schemas.PetResponse(
            pet_id=pet.pet_id,
            pet_first_name=pet.pet_first_name,
            pet_last_name=pet.pet_last_name,
            species_name=species_map.get(pet.species_id, "Unknown"),
            owner_id=pet.owner_id,
            species_id=pet.species_id,
            pet_image_path=pet.pet_image_path,
        )
        for pet in pets
    ]


@router.put("/{pet_id}", response_model=schemas.PetResponse)
def update_pet(pet_id: int, pet_update: schemas.PetCreate, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(get_db)):
    db_pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not db_pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    if db_pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    db_pet.pet_first_name = pet_update.pet_first_name
    db_pet.pet_last_name = pet_update.pet_last_name

    db.commit()
    db.refresh(db_pet)
    return db_pet


@router.delete("/{pet_id}")
def delete_pet(pet_id: int, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(get_db)):
    db_pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not db_pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    if db_pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    db.delete(db_pet)
    db.commit()
    return {"message": f"Pet {pet_id} and all associated data deleted successfully"}


@router.put("/{pet_id}/image")
async def update_pet_image(pet_id: int, image_url: str, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(get_db)):
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    if pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    pet.pet_image_path = image_url
    db.commit()
    return {"message": "Image updated"}
