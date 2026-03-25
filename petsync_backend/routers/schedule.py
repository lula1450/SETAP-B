from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import date, time
from typing import List, Optional

# Database session provider and models
from petsync_backend import models
from petsync_backend.database import get_db

router = APIRouter(
    prefix="",
    tags=["Scheduling & Reminders"]
)

# --- 1. SCHEMAS (Data Validation) ---

class AppointmentCreate(BaseModel):
    pet_id: int
    appointment_date: date
    appointment_time: time
    notes: Optional[str] = None

class AppointmentUpdate(BaseModel):
    new_date: date
    new_time: time
    notes: Optional[str] = None

class FeedingScheduleCreate(BaseModel):
    pet_id: int
    feeding_time: time
    food_type: str

class FeedingScheduleUpdate(BaseModel):
    new_time: time
    food_type: Optional[str] = None

class ReminderCreate(BaseModel):
    pet_id: int
    reminder_time: time
    reminder_message: str

class ReminderUpdate(BaseModel):
    new_time: time
    new_message: str

# --- 2. CREATE ROUTES ---

@router.post("/appointments", status_code=status.HTTP_201_CREATED)
def create_pet_appointment(appointment: AppointmentCreate, db: Session = Depends(get_db)):
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
def create_feeding_schedule(schedule: FeedingScheduleCreate, db: Session = Depends(get_db)):
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
def create_reminder(reminder: ReminderCreate, db: Session = Depends(get_db)):
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

@router.get("/appointments/pet/{pet_id}")
def get_pet_appointments(pet_id: int, db: Session = Depends(get_db)):
    return db.query(models.PetAppointment).filter(models.PetAppointment.pet_id == pet_id).all()

@router.get("/feeding-schedules/pet/{pet_id}")
def get_feeding_schedules(pet_id: int, db: Session = Depends(get_db)):
    return db.query(models.FeedingSchedule).filter(models.FeedingSchedule.pet_id == pet_id).all()

# --- 4. UPDATE ROUTES ---

@router.put("/appointments/{appointment_id}")
def update_pet_appointment(appointment_id: int, update: AppointmentUpdate, db: Session = Depends(get_db)):
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
    
    db.delete(appointment)
    db.commit()
    return None