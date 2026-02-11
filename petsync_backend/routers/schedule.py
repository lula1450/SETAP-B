# This manager handles the creation of the pet's schedules, handling aspects that are time based
# e.g. vet appointments, feeding times and reminders. Uses fastapi and sqlalchemy packages

from fastapi import APIRouter, HTTPException
from sqlalchemy.orm import session
from datetime import datetime

from models import PetAppointment, FeedingSchedule, Reminder