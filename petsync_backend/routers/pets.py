# Pet Manament router 

from fastapi import APIRouter, Depends, HTTPException 
#creates a miniture app for the pet-related endpoints only 
#injects a datbase connection into evert endpoint 
from sqlalchemy.orm import Session 
from sqlalchemy import func 
from petsync_backend import models, schemas 
from petsync_backend.database import get_db 

 
 
router = APIRouter() 
#creates the pet router container 

 

""" 1. Create the pet profile endpoint and adds the pet to the database  
and also checks if the owner already exists"""  
@router.post("/", reponse_model=models.PetResponse) 
def create_pet(pet: models.PetCreate, db: Session = Depends(get_db)): 
#FR6: Create pet profile with species-specific data""" 
    owner = db.query(models.User).filter(models.User.user_id == pet.owner_id).first() 
    if not owner: 
        raise HTTPException(status_code = 404, detail = "Owner not found") 
    
    db_pet = models.Pet( 
        species_id = pet.species_id, 
        owner_id = pet.owner_id, 
        pet_first_name = pet.pet_first_name, 
        pet_last_name = pet.pet_last_name, 
        pet_address1 = pet.pet_address1, 
        pet_address2 = pet.pet_address2, 
        pet_city = pet.pet_city, 
    ) 

    db.add(db_pet) 
    db.commit() 
    db.refresh(db_pet) 

 
    return schemas.PetResponse( 
        pet_id = db_pet.pet_id, 
        species_id = db_pet.species_id, 
        owner_id = db_pet.owner_id, 
        pet_first_name = db_pet.pet_first_name, 

) 


""" 2. Gets a single pet with it species info""" 
""" Retrieves the pet with joins to species_config, user_pet""" 
@router.get("/{pet_id}", reponse_model=models.PetResponse) 
def get_pet(pet_id: int, db: Session = Depends(get_db)): 
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first() 
    if not pet: 
        raise HTTPException(status_code = 404, detial = "Pet not found") 
    
    species = db.query(models.SpeciesConfig).filter(models.SpeciesConfig.species_id == pet.species_id).first() 

    return schemas.PetResponse( 
        pet_id = pet.pet_id, 
        pet_first_name = pet.pet_first_name, 
        species_name = pet.species_name if species else "Unknown", 

) 


""" 3. List all the owner's pets """ 
@router.get("/owner/{owner_id}", response_model=list[models.PetResponse])
def list_all_pets(owner_id: int, db: Session = Depends(get_db)):
    pets = db.query(models.Pet).filter(models.Pet.owner_id == owner_id).all()
    if not pets:
        raise HTTPException(status_code=404, detail="No pets found for this owner")
    return [
        schemas.PetResponse(
            pet_id=pet.pet_id,
            pet_first_name=pet.pet_first_name,
            species_name=db.query(models.SpeciesConfig).filter(models.SpeciesConfig.species_id == pet.species_id).first().species_name
            if db.query(models.SpeciesConfig).filter(models.SpeciesConfig.species_id == pet.species_id).first() else "Unknown"
        )
        for pet in pets
    ]



""" 4. species-specific care tips for a pet """ 
"""FR5: Species intelligence from species_config table""" 

@router.get("/{pet_id}/care-tips") 
def get_species_info(pet_id: int, db: Session = Depends(get_db)): 
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first() 
    if not pet: 
        raise HTTPException(status_code = 404, detail = "Pet not found") 
    
    #Query your species_config table(species_id-> speices_name -> notes) 
    species_tips = db.query(models.SpeciesConfig).filter( 
    models.SpeciesConfig.species_id == pet.species_id 
    ).first() 

    if not species_tips: 
        return { 
        "pet_id": pet_id, 
        "species": "Unknown", 
        "tips": ["No species config found"], 
        "message": "Add specied data to species_config table" 
    }

    return { 
        "pet_id": pet_id, 
        "species": species_tips.species_name, 
        "care_tips": species_tips.notes, # Your schema's TEXT field for tips 
        "care_tips_json": [species_tips.notes] # For frontend 
} 

 

""" 5. Medical records for a pet """  
"""FR6: Medical records from medical_detail table""" 
@router.get("/{pet_id}/medical") 
def get_medical_details(pet_id: int, db: Session = Depends(get_db)): 
    medical = db.query(models.MedicalDetail).filter( 
    models.MedicalDetail.pet_id == pet_id 
    ).first() 

    if not medical: 
        raise HTTPException(status_code = 404, detail = "No medical details found") 

    return { 
        "pet_id": pet_id, 
        "blood_type": medical.blood_type, 
        "allergies": medical.allergies, 
        "medication": medical.current_medication, 
        "microchip_id": medical.microchip_id, 
        "spay_neutered": medical.spay_neutered 

} 

 

 






