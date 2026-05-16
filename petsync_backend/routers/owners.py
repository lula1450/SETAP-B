from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta, timezone
import bcrypt
from petsync_backend import models, schemas, database
from petsync_backend.utils.auth_utils import get_current_owner_id

router = APIRouter()

DELETION_GRACE_DAYS = 30


def _hash_password(plain: str) -> str:
    """Hashes a plain-text password using bcrypt."""
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def purge_owner(owner: models.Owner, db: Session) -> None:
    """
    Permanently deletes an owner and all associated data from the database.

    Removes pets, health metrics, goals, metadata, feeding schedules, appointments,
    reminders, and reports before deleting the owner record itself.
    Called when a scheduled deletion grace period expires.
    """
    pets = db.query(models.Pet).filter(models.Pet.owner_id == owner.owner_id).all()
    for pet in pets:
        db.query(models.PetMetaData).filter(models.PetMetaData.pet_id == pet.pet_id).delete()
        db.query(models.PetGoal).filter(models.PetGoal.pet_id == pet.pet_id).delete()

        schedule_ids = db.query(models.FeedingSchedule.feeding_schedule_id).filter(
            models.FeedingSchedule.pet_id == pet.pet_id
        ).subquery()
        db.query(models.Reminder).filter(
            models.Reminder.feeding_schedule_id.in_(schedule_ids)
        ).delete(synchronize_session=False)
        db.query(models.FeedingSchedule).filter(models.FeedingSchedule.pet_id == pet.pet_id).delete()

        appt_ids = db.query(models.PetAppointment.pet_appointment_id).filter(
            models.PetAppointment.pet_id == pet.pet_id
        ).subquery()
        db.query(models.Reminder).filter(
            models.Reminder.pet_appointment_id.in_(appt_ids)
        ).delete(synchronize_session=False)
        db.query(models.PetAppointment).filter(models.PetAppointment.pet_id == pet.pet_id).delete()

        db.query(models.HealthMetric).filter(models.HealthMetric.pet_id == pet.pet_id).delete()
        db.query(models.PetReport).filter(models.PetReport.pet_id == pet.pet_id).delete()
        db.delete(pet)

    db.delete(owner)
    db.commit()


@router.post("/", response_model=schemas.OwnerResponse, status_code=201)
def create_owner(owner: schemas.OwnerCreate, db: Session = Depends(database.get_db)):
    """Creates a new owner account. Raises 400 if the email is already registered."""
    db_owner = db.query(models.Owner).filter(models.Owner.owner_email == owner.owner_email).first()
    if db_owner:
        raise HTTPException(status_code=400, detail="Email already registered")

    data = owner.model_dump()
    data["password"] = _hash_password(data["password"])
    new_owner = models.Owner(**data)
    db.add(new_owner)
    db.commit()
    db.refresh(new_owner)
    return new_owner


@router.get("/{owner_id}", response_model=schemas.OwnerResponse)
def get_owner(owner_id: int, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(database.get_db)):
    """Returns the profile of the specified owner. Raises 403 if not the authenticated user, 404 if not found."""
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    if current_owner_id != owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return owner


@router.delete("/{owner_id}")
def delete_owner(owner_id: int, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(database.get_db)):
    """
    Schedules the account for permanent deletion after a 30-day grace period.

    If deletion is already pending, returns the existing scheduled date. The owner
    and all their data are purged automatically once the grace period expires.
    """
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    if current_owner_id != owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    if owner.deletion_requested_at:
        purge_at = owner.deletion_requested_at + timedelta(days=DELETION_GRACE_DAYS)
        return {
            "message": "Account is already scheduled for deletion.",
            "deletion_requested_at": owner.deletion_requested_at.isoformat(),
            "scheduled_purge_at": purge_at.isoformat(),
        }

    owner.deletion_requested_at = datetime.now(timezone.utc)
    db.commit()
    purge_at = owner.deletion_requested_at + timedelta(days=DELETION_GRACE_DAYS)
    return {
        "message": f"Account scheduled for deletion. All data will be permanently removed on {purge_at.date()}. You have {DELETION_GRACE_DAYS} days to cancel.",
        "deletion_requested_at": owner.deletion_requested_at.isoformat(),
        "scheduled_purge_at": purge_at.isoformat(),
    }


@router.post("/{owner_id}/cancel-deletion")
def cancel_deletion(owner_id: int, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(database.get_db)):
    """Cancels a pending account deletion request and restores the account to active. Raises 400 if no deletion is pending."""
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    if current_owner_id != owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    if not owner.deletion_requested_at:
        raise HTTPException(status_code=400, detail="No pending deletion request for this account.")

    owner.deletion_requested_at = None
    db.commit()
    return {"message": "Account deletion cancelled. Your account is now active."}


@router.put("/{owner_id}", response_model=schemas.OwnerResponse)
def update_owner(owner_id: int, owner_data: schemas.OwnerUpdate, current_owner_id: int = Depends(get_current_owner_id), db: Session = Depends(database.get_db)):
    """
    Updates the owner's profile fields (name, email, password).
    Only fields present in the request body are updated. Passwords are re-hashed before storing.
    """
    db_owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not db_owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    if current_owner_id != owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")

    update_data = owner_data.model_dump(exclude_unset=True)
    if "password" in update_data and update_data["password"] is not None:
        update_data["password"] = _hash_password(update_data["password"])
    for key, value in update_data.items():
        if value is not None and hasattr(db_owner, key):
            setattr(db_owner, key, value)

    db.commit()
    db.refresh(db_owner)
    return db_owner