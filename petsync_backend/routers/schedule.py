
from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import date, time

# database session provider
from database import get_db

# database models
from models import PetAppointment, FeedingSchedule, Reminder


router = APIRouter(
    prefix="/schedule",
    tags=["Scheduling & Reminders"]
)


# simple test route
@router.get("/")
async def status_check():
    return {"message": "Feature pending implementation"}


# SCHEMAS

class AppointmentCreate(BaseModel):
    pet_id: int
    appointment_date: date
    appointment_time: time

class AppointmentUpdate(BaseModel):
    new_date: date
    new_time: time

class FeedingScheduleCreate(BaseModel):
    pet_id: int
    feeding_time: time
    food_type: str

class FeedingScheduleUpdate(BaseModel):
    new_time: time

class ReminderCreate(BaseModel):
    pet_id : int
    reminder_time: time
    reminder_message: str

class ReminderUpdate(BaseModel):
    new_time: time
    new_message: str

#CREATE

@router.post("/appointments", status_code=status.HTTP_201_CREATED)
def create_pet_appointment(appointment: AppointmentCreate, db: Session = Depends(get_db)):
    new_appointment = PetAppointment(
        pet_id=appointment.pet_id,
        pet_appointment_date=appointment.appointment_date,
        pet_appointment_time=appointment.appointment_time,
        appointment_status="SCHEDULED"
    )

    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)

    return new_appointment

@router.post("/feeding-schedules", status_code=status.HTTP_201_CREATED)
def create_feeding_schedule(schedule: FeedingScheduleCreate, db: Session = Depends(get_db)):
    new_schedule = FeedingSchedule(
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
    new_reminder = Reminder(
        pet_id=reminder.pet_id,
        reminder_time=reminder.reminder_time,
        reminder_message=reminder.reminder_message
    )

    db.add(new_reminder)
    db.commit()
    db.refresh(new_reminder)

    return new_reminder


# UPDATE

@router.put("/appointments/{appointment_id}")
def update_pet_appointment(appointment_id: int, appointment_update: AppointmentUpdate, db: Session = Depends(get_db)):
    appointment = db.get(PetAppointment, appointment_id)

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    appointment.pet_appointment_date = appointment_update.new_date
    appointment.pet_appointment_time = appointment_update.new_time
    db.commit()
    db.refresh(appointment)

    return appointment

@router.put("/feeding-schedules/{schedule_id}")
def update_feeding_schedule(schedule_id: int, schedule_update: FeedingScheduleUpdate, db: Session = Depends(get_db)):
    schedule = db.get(FeedingSchedule, schedule_id)

    if not schedule:
        raise HTTPException(status_code=404, detail="Feeding schedule not found")

    schedule.feeding_time = schedule_update.new_time
    db.commit()
    db.refresh(schedule)

    return schedule

@router.put("/reminders/{reminder_id}")
def update_reminder(reminder_id: int, reminder_update: ReminderUpdate, db: Session = Depends(get_db)):
    reminder = db.get(Reminder, reminder_id)

    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    reminder.reminder_time = reminder_update.new_time
    reminder.reminder_message = reminder_update.new_message
    db.commit()
    db.refresh(reminder)

    return reminder

# DELETE

@router.delete("/appointments/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_pet_appointment(appointment_id: int, db: Session = Depends(get_db)):
    appointment = db.get(PetAppointment, appointment_id)

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    db.delete(appointment)
    db.commit()

@router.delete("/feeding-schedules/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_feeding_schedule(schedule_id: int, db: Session = Depends(get_db)):
    schedule = db.get(FeedingSchedule, schedule_id)

    if not schedule:
        raise HTTPException(status_code=404, detail="Feeding schedule not found")

    db.delete(schedule)
    db.commit()

@router.delete("/reminders/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_reminder(reminder_id: int, db: Session = Depends(get_db)):
    reminder = db.get(Reminder, reminder_id)

    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")

    db.delete(reminder)
    db.commit()
