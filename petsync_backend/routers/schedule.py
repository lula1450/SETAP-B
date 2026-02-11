# This manager handles the creation of the pet's schedules, handling aspects that are time based
# e.g. vet appointments, feeding times and reminders. Uses fastapi and sqlalchemy packages

# Imports required for request routing, database interaction, and handling
# time-based scheduling data within the Scheduling & Reminders Service.
from fastapi import APIRouter, HTTPException
from sqlalchemy.orm import session
from datetime import datetime

#imports from the models.py file, these are database tables represented in python
from models import PetAppointment, FeedingSchedule, Reminder

