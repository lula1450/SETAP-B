from fastapi import APIRouter

# This allows main.py to "include" this section of the API
router = APIRouter()

@router.get("/")
async def status():
    return {"message": "Feature pending implementation"}




# This manager handles the creation of the pet's schedules, handling aspects that are time based
# e.g. vet appointments, feeding times and reminders. Uses fastapi and sqlalchemy packages

'''
# Imports required for request routing, database interaction, and handling
# time-based scheduling data within the Scheduling & Reminders Service.
from fastapi import APIRouter, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, date, time

#imports from the models.py file, these are database tables represented in python
from models import PetAppointment, FeedingSchedule, Reminder

router = APIRouter(
    prefix = "/schedule",
    tags = ["Scheduling & Reminders"]
)

#Function to create pet appointment 

@router.post("/Appointments")
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

'''