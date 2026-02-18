from fastapi import APIRouter, HTTPException, Depends
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
async def status():
    return {"message": "Feature pending implementation"}


# create pet appointment
@router.post("/appointments")
def create_pet_appointment(
    pet_id: int,
    appointment_date: date,
    appointment_time: time,
    db: Session = Depends(get_db)
):
    appointment = PetAppointment(
        pet_id=pet_id,
        pet_appointment_date=appointment_date,
        pet_appointment_time=appointment_time,
        appointment_status="SCHEDULED"
    )

    db.add(appointment)
    db.commit()
    db.refresh(appointment)

    return appointment


# create feeding schedule
@router.post("/feeding-schedules")
def create_feeding_schedule(
    pet_id: int,
    feeding_time: time,
    food_type: str,
    db: Session = Depends(get_db)
):
    schedule = FeedingSchedule(
        pet_id=pet_id,
        feeding_time=feeding_time,
        food_type=food_type
    )

    db.add(schedule)
    db.commit()
    db.refresh(schedule)

    return schedule

# create reminder
@router.post("/reminders")
def create_reminder(
    pet_id: int,
    reminder_time: time,
    reminder_message: str,
    db: Session = Depends(get_db)
):
    reminder = Reminder(
        pet_id=pet_id,
        reminder_time=reminder_time,
        reminder_message=reminder_message
    )

    db.add(reminder)
    db.commit()
    db.refresh(reminder)

    return reminder

#delete pet appointment
@router.delete("/appointments/{appointment_id}")
def delete_pet_appointment(appointment_id: int, db: Session = Depends(get_db)):
    appointment = db.query(PetAppointment).filter(PetAppointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    db.delete(appointment)
    db.commit()
    return {"message": "Appointment deleted successfully"}

#delete feeding schedule
@router.delete("/feeding-schedules/{schedule_id}")
def delete_feeding_schedule(schedule_id: int, db: Session = Depends(get_db)):
    schedule = db.query(FeedingSchedule).filter(FeedingSchedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Feeding schedule not found")
    
    db.delete(schedule)
    db.commit()
    return {"message": "Feeding schedule deleted successfully"}

#delete reminder
@router.delete("/reminders/{reminder_id}")
def delete_reminder(reminder_id: int, db: Session = Depends(get_db)):
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
    
    db.delete(reminder)
    db.commit()
    return {"message": "Reminder deleted successfully"}