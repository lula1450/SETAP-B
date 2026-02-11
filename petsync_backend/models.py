# This manager represents the ERD in python, used so other managers can import the tables
# each class represents a table along with its PKs and FKs. Uses SQLalchemy to create the tables

#imports necessary to create the database tables in python
from sqlalchemy import Column, Integer, String, Date, Time, ForeignKey, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

# Creates a class that where if a class inherits it, it is a database table
Base = declarative_base()

#Creation of the PetAppointment table
class PetAppointment(Base):
    __tablename__ = "pet_appointment"

    pet_appointment_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False)

    pet_appointment_date = Column(Date, nullable=False)
    pet_appointment_time = Column(Time, nullable=False)
    appointment_status = Column(String, nullable=False)

#Creation of the FeedingSchedule table
class FeedingSchedule(Base):
    __tablename__ = "feeding_schedule"

    feeding_schedule_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False)

    fschedule_start = Column(Date, nullable=False)
    fschedule_end = Column(Date, nullable=False)

    feed_time = Column(DateTime, nullable=False)
    portion_size = Column(Integer, nullable=False)
    food_name = Column(String(100), nullable=False)

#Creation of the Reminder table
class Reminder(Base):
    __tablename__ = "reminder"

    reminder_id = Column(Integer, primary_key=True, index=True)

    pet_appointment_id = Column(
        Integer,
        ForeignKey("pet_appointment.pet_appointment_id"),
        nullable=True
    )

    feeding_schedule_id = Column(
        Integer,
        ForeignKey("feeding_schedule.feeding_schedule_id"),
        nullable=True
    )

    reminder_time = Column(DateTime, nullable=False)
    reminder_status = Column(String, nullable=False)
    reminder_notes = Column(String)

