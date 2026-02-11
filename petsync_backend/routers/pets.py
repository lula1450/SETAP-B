# Pet Manament router

from fastapi import APIRouter, Depends, HTTPException
#creates a miniture app for the pet-related endpoints only
#injects a datbase connection into evert endpoint
from sqlalchemy.orm import Session
from sqlalchemy import func
from app import models, crud
from app.database import get_db


router = APIRouter()
#creates the pet router container

@router.post("/", reponse_model=models.PetResponse)
def create_pet(pet: models.PetCreate, db: Session = Depends(get_db)):
    """ FR6: Create pet profile with species-specific data"""
    return crud.create_pet(db, pet)


@router.get("/{pet_id}", reponse_model=models.PetResponse)
def get_pet(pet_id: int, db: Session = Depends(get_db)):
    """ Get pet eith joins to species_config,  user_pet, medical detail"""
    pet = crud.get_pet(db, pet_id)
    """FR5: Get species-specific care info"""
    if not pet:
        raise HTTPException(404, "Pet not found")
    return pet

# Allows you to get a single pet
# the fucntion turns the url into an interger, validates it and queries it in PostgreSQL
# it then uses the if statement to check if the query return nothing then
# return an error of the id is not found, otherwise return the pet

@router.get("/{pet_id}/care-tips")
def get_species_info(pet_id: int, db: Session = Depends(get_db)):
    """FR5: Species intelligence from species_config table"""
    pet = crud.get_pet(db, pet_id)
    if not pet:
        raise HTTPException(404, "Pet not found")

    #Query yourr species_config table(species_id-> speices_name -> notes)
    species_tips = db.query(models.SpeciesConfig).filter(
        models.SpeciesConfig.species_id == pet.species_id
    ).first()

    if not species_tips:
        return {
            "pet_id": pet_id
            "species": "Unknown"
            "tips": ["No species config found"],
            "message": "Add specied data to species_config table"
        }

        return {
            "pet_id": pet_id,
            "species": species_tips.species_name,
            "breed": species_tips.breed_name,
            "care_tips": species_tips.notes,  # Your schema's TEXT field for tips
            "care_tips_json": [species_tips.notes]  # For frontend
        }
    
@router.get("/{pet_id}/medical")
def get_medical_details(pet_id: int, db: Session = Depend(get_db)):
     """FR6: Medical records from medical_detail table"""
    medical = db.query(models.MedicalDetail).filter(
        models.MedicalDetail.pet_id == pet_id
    ).first()

    if not medical:
        raise HTTPException(404, "No medical details found")
    
    return {
        "pet_id": pet_id,
        "blood_type": medical.blood_type,
        "allergies": medical.allergies,
        "medication": medical.current_medication,
        "microchip_id": medical.microchip_id,
        "spay_neutered": medical.spay_neutered
    }