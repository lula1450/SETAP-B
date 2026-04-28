from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from petsync_backend import models, database

router = APIRouter()

# --- SCHEMAS ---
class VetContactCreate(BaseModel):
    owner_id: int
    clinic_name: str
    phone: str
    email: str
    address: str

class VetContactUpdate(BaseModel):
    clinic_name: str
    phone: str
    email: str
    address: str

class VetContactResponse(BaseModel):
    vet_id: int
    clinic_name: str
    phone: str
    email: str
    address: str

    class Config:
        from_attributes = True

# --- GET VET CONTACTS FOR OWNER ---
@router.get("/owner/{owner_id}", response_model=List[dict])
def get_owner_vet_contacts(owner_id: int, db: Session = Depends(database.get_db)):
    """Get all vet contacts for an owner"""
    vets = db.query(models.VetContact).filter(models.VetContact.owner_id == owner_id).all()
    
    if not vets:
        return []
    
    return [
        {
            "vet_id": v.vet_id,
            "clinic_name": v.clinic_name,
            "phone": v.phone,
            "email": v.email,
            "address": v.address,
        }
        for v in vets
    ]


# --- CREATE VET CONTACT ---
@router.post("/create", response_model=VetContactResponse, status_code=201)
def create_vet_contact(vet_data: VetContactCreate, db: Session = Depends(database.get_db)):
    """Create a new vet contact for an owner"""
    # Verify owner exists
    owner = db.query(models.Owner).filter(models.Owner.owner_id == vet_data.owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    
    # Check if contact already exists
    existing = db.query(models.VetContact).filter(
        models.VetContact.owner_id == vet_data.owner_id,
        models.VetContact.clinic_name == vet_data.clinic_name
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Vet contact already exists")
    
    # Create new vet contact
    vet_contact = models.VetContact(
        owner_id=vet_data.owner_id,
        clinic_name=vet_data.clinic_name,
        phone=vet_data.phone,
        email=vet_data.email,
        address=vet_data.address
    )
    
    db.add(vet_contact)
    db.commit()
    db.refresh(vet_contact)
    
    return vet_contact


# --- DELETE VET CONTACT ---
@router.delete("/{vet_id}")
def delete_vet_contact(vet_id: int, db: Session = Depends(database.get_db)):
    """Delete a vet contact"""
    vet = db.query(models.VetContact).filter(models.VetContact.vet_id == vet_id).first()
    
    if not vet:
        raise HTTPException(status_code=404, detail="Vet contact not found")
    
    db.delete(vet)
    db.commit()
    
    return {"message": f"Vet contact {vet_id} deleted successfully"}


# --- UPDATE VET CONTACT ---
@router.put("/{vet_id}", response_model=VetContactResponse)
def update_vet_contact(vet_id: int, vet_data: VetContactUpdate, db: Session = Depends(database.get_db)):
    """Update a vet contact"""
    vet = db.query(models.VetContact).filter(models.VetContact.vet_id == vet_id).first()
    
    if not vet:
        raise HTTPException(status_code=404, detail="Vet contact not found")
    
    # Update fields
    vet.clinic_name = vet_data.clinic_name
    vet.phone = vet_data.phone
    vet.email = vet_data.email
    vet.address = vet_data.address
    
    db.commit()
    db.refresh(vet)
    
    return vet
