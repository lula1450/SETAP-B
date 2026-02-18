# This manager represents the ERD in python, used so other managers can import the tables
# each class represents a table along with its PKs and FKs. Uses SQLalchemy to create the tables

#imports necessary to create the database tables in python
from sqlalchemy import Column, Integer, String, Date, Time, ForeignKey, DateTime, Enum, Text, Numeric, Timestamp, Boolean
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import enum

# Creates a class that where if a class inherits it, it is a database table
Base = declarative_base()

#Creation of owner table
class Owner(Base):
    __tablename__ = "owner"

    owner_id = Column(Integer, primary_key=True)

    owner_first_name = Column(String(50), nullable=False, index=True)
    owner_last_name = Column(String(100), nullable=False, index=True)
    owner_email = Column(String(100), unique=True, nullable=False, index=True)
    owner_phone_number = Column(String(15), unique=True, nullable=False, index=True)
    owner_address1 = Column(String(100), nullable=False)
    owner_address2 = Column(String(100))
    owner_postcode = Column(String(10), nullable=False)
    owner_city = Column(String(30), nullable=False, default="London")

#Creation of Pet table
class Pet(Base):
    __tablename__ = "pet"

    pet_id = Column(Integer, primary_key=True, index=True)
    species_id = Column(Integer, ForeignKey("species_config.species_id"), nullable=False)
    owner_id = Column(Integer, ForeignKey("owner.owner_id"), nullable=False)

    pet_first_name = Column(String(50), nullable=False)
    pet_last_name = Column(String(50))
    pet_address1 = Column(String(100), nullable=False)
    pet_address2 = Column(String(100))
    pet_postcode = Column(String(10), nullable=False)
    pet_city = Column(String(30), nullable=False)

#Creation of species_config table
class Species_config(Base):
    __tablename__ = "species_config"

    species_id = Column(Integer, primary_key=True, nullable=False, index=True)
    
    species_name = Column(String(20), nullable=False, index=True)
    breed_name = Column(String(20), nullable=False)
    notes = Column(Text, nullable=False)

#Creation of MedicalDetails table    
class SpayNeuteredStatus(enum.Enum):
    Yes = "Yes"
    No = "No"
    NA = "N/A"

class MedicalDetail(Base):

    __tablename__ = "medical_detail"

    medical_detail_id = Column(Integer, primary_key=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False)

    blood_type = Column(String(20))
    medical_notes = Column(Text)
    current_medication = Column(Text)
    allergies = Column(Text)
    microchip_id = Column(String(15))
    spay_neutered = Column(Enum(SpayNeuteredStatus, name="spay_neutered_status"), nullable=False, default=SpayNeuteredStatus.NA)

#Creation of MetaDeta table
class PetMetaData(Base):
    __tablename__ = "metadata"

    meta_data_id = Column(Integer, primary_key=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)
    notes = Column(Text, nullable=False)

class MetricName(enum.Enum):
    weight = "weight"
    stool_quality = "stool_quality"
    energy_level = "energy_level"
    appetite = "appetite"
    water_intake = "water_intake"
    litter_box_usage = "litter_box_usage"
    grooming_frequency = "grooming_frequency"
    vomit_events = "vomit_events"
    feather_condition = "feather_condition"
    wing_strength = "wing_strength"
    perch_activity = "perch_activity"
    vocalisation_level = "vocalisation_level"
    basking_time = "basking_time"
    shedding_quality = "shedding_quality"
    humidity_level = "humidity_level"
    stool_pellets = "stool_pellets"
    chewing_behaviour = "chewing_behaviour"
    wheel_activity = "wheel_activity"
    custom = "custom"

class MetricUnit(enum.Enum):
    kg = "kg"
    grams = "grams"
    ml = "ml"
    scale_1_5 = "scale_1_5"
    count_day = "count_day"
    minutes_day = "minutes_day"
    percent = "percent"
    text = "text"
    custom = "custom"

#Creation of MetricDefinition table
class MetricDefinition(Base):
    __tablename__ = "metric_definition"

    metric_def_id = Column(Integer, primary_key=True)
    species_id = Column(Integer, ForeignKey("species_config.species"), nullable=False, index=True)
    metric_name = Column(Enum(MetricName, name="metric_name"),nullable=False, index=True)
    metric_unit = Column(Enum(MetricUnit, name="metric_unit"), nullable=False)
    notes = Column(Text)

#Creation of HealthMetric table
class HealthMetric(Base):
    __tablename__ = "health_metric"

    health_metric_id = Column(Integer, primary_key=True, nullable=False, index=True)
    metric_def_id = Column(Integer, ForeignKey("metric_defintion.metric_def_id"), nullable=False, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)
    metric_value = Column(Numeric)
    metric_time = Column(DateTime, nullable=False, index=True)
    notes = Column(Text, nullable=True)

#Creation of the PetAppointment table
class AppointmentStatus(enum.Enum):
    Scheduled = "Scheduled"
    Completed = "Completed"
    Cancelled = "Cancelled"

class AppointmentReminderFrequency(enum.Enum):
    once = "once"
    daily = "daily"
    weekly = "weekly"
    none = "none"

class PetAppointment(Base):
    __tablename__ = "pet_appointment"

    pet_appointment_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)

    enable_reminder = Column(Boolean, nullable=False, default=True)
    reminder_frequency = Column(Enum(AppointmentReminderFrequency, name="reminder_frequency") ,nullable=False, default=AppointmentReminderFrequency.daily)
    pet_appointment_date = Column(Date, nullable=False, index=True)
    pet_appointment_time = Column(Time, nullable=False, index=True)
    appointment_status = Column(Enum(AppointmentStatus, name="appointment_status"), nullable=False, default=AppointmentStatus.Scheduled)

#Creation of the FeedingSchedule table
class FeedingSchedule(Base):
    __tablename__ = "feeding_schedule"

    feeding_schedule_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)

    feeding_schedule_start = Column(Date, nullable=False, index=True)
    feeding_schedule_end = Column(Date, nullable=False, index=True)
    feeding_time = Column(DateTime, nullable=False)
    portion_size = Column(Integer, nullable=False)
    food_name = Column(String(100), nullable=False)

#Creation of the Reminder table
class ReminderStatus(enum.Enum):
    pending = "Pending"
    sent = "Sent"
    dismissed = "Dismissed"
    missed = "Missed"
    cancelled = "Cancelled"

class Reminder(Base):
    __tablename__ = "reminder"

    reminder_id = Column(Integer, primary_key=True, index=True)
    pet_appointment_id = Column(Integer, ForeignKey("pet_appointment.pet_appointment_id"), nullable=True)
    feeding_schedule_id = Column(Integer, ForeignKey("feeding_schedule.feeding_schedule_id"), nullable=True)

    reminder_date = Column(Date, nullable=False)
    reminder_time = Column(DateTime, nullable=False)
    reminder_status = Column(Enum(ReminderStatus, name="reminder_status"), nullable=False, default=ReminderStatus.pending)
    reminder_notes = Column(Text)

