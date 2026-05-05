from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session

from petsync_backend import models, schemas
from petsync_backend.database import get_db

router = APIRouter(
    prefix="",
    tags=["Scheduling & Reminders"]
)

# --- 1. CREATE ROUTES ---

@router.post("/appointments", status_code=status.HTTP_201_CREATED)
def create_pet_appointment(appointment: schemas.AppointmentCreate, db: Session = Depends(get_db)):
    new_appointment = models.PetAppointment(
        pet_id=appointment.pet_id,
        pet_appointment_date=appointment.appointment_date,
        pet_appointment_time=appointment.appointment_time,
        appointment_status="Scheduled",
        appointment_notes=appointment.notes
    )
    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)
    return new_appointment

@router.post("/feeding-schedules", status_code=status.HTTP_201_CREATED)
def create_feeding_schedule(schedule: schemas.FeedingScheduleCreate, db: Session = Depends(get_db)):
    new_schedule = models.FeedingSchedule(
        pet_id=schedule.pet_id,
        feeding_time=schedule.feeding_time,
        food_name=schedule.food_type
    )
    db.add(new_schedule)
    db.commit()
    db.refresh(new_schedule)
    return new_schedule

@router.post("/reminders", status_code=status.HTTP_201_CREATED)
def create_reminder(reminder: schemas.ReminderCreate, db: Session = Depends(get_db)):
    new_reminder = models.Reminder(
        pet_id=reminder.pet_id,
        reminder_time=reminder.reminder_time,
        reminder_message=reminder.reminder_message
    )
    db.add(new_reminder)
    db.commit()
    db.refresh(new_reminder)
    return new_reminder

# --- 3. GET (READ) ROUTES ---

# petsync_backend/routers/schedule.py

@router.get("/appointments/owner/{owner_id}")
def get_all_owner_appointments(owner_id: int, db: Session = Depends(get_db)):
    # Join with the Pet table to ensure we only get pets belonging to this owner
    return db.query(models.PetAppointment).join(models.Pet).filter(models.Pet.owner_id == owner_id).all()

@router.get("/feeding-schedules/pet/{pet_id}")
def get_feeding_schedules(pet_id: int, db: Session = Depends(get_db)):
    return db.query(models.FeedingSchedule).filter(models.FeedingSchedule.pet_id == pet_id).all()

# --- 4. UPDATE ROUTES ---

@router.put("/appointments/{appointment_id}")
def update_pet_appointment(appointment_id: int, update: schemas.AppointmentUpdate, db: Session = Depends(get_db)):
    appointment = db.query(models.PetAppointment).filter(
        models.PetAppointment.pet_appointment_id == appointment_id
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    appointment.pet_appointment_date = update.new_date
    appointment.pet_appointment_time = update.new_time
    appointment.appointment_notes = update.notes
    
    db.commit()
    db.refresh(appointment)
    return appointment

# --- 5. DELETE ROUTES ---

@router.delete("/appointments/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_pet_appointment(appointment_id: int, db: Session = Depends(get_db)):
    appointment = db.query(models.PetAppointment).filter(
        models.PetAppointment.pet_appointment_id == appointment_id
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Delete all reminders associated with this appointment first
    db.query(models.Reminder).filter(
        models.Reminder.pet_appointment_id == appointment_id
    ).delete()
    
    # Now delete the appointment
    db.delete(appointment)
    db.commit()
    return None