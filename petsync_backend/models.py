from sqlalchemy import Column, Integer, String, Date, Time, ForeignKey, DateTime, Enum, Text, Numeric, Boolean
from sqlalchemy.orm import declarative_base # tells SQLAlchemy that this is the base class for our models
from datetime import datetime
import enum
from sqlalchemy.orm import relationship # for defining relationships between tables

# this file defines the database tables for the app using
# SqlAlchemy's (python Object relational mapper)

# Base class for all models
Base = declarative_base()

class Owner(Base):
    __tablename__ = "owner"

    owner_id = Column(Integer, primary_key=True)
    owner_first_name = Column(String(50), nullable=False, index=True)
    owner_last_name = Column(String(100), nullable=False, index=True)
    owner_email = Column(String(100), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False, default="password123")
    deletion_requested_at = Column(DateTime, nullable=True)

    # Relationship to pets
    pets = relationship("Pet", backref="owner", cascade="all, delete")

class SpeciesType(enum.Enum):
    dog = "dog"
    cat = "cat"
    hamster = "hamster"
    snake = "snake"
    bird = "bird"
    rabbit = "rabbit"

class Species_config(Base):
    __tablename__ = "species_config"

    species_id = Column(Integer, primary_key=True, nullable=False, index=True)
    species_name = Column(Enum(SpeciesType, name="species_type"), nullable=False)
    breed_name = Column(String(20), nullable=False)
    notes = Column(Text, nullable=False)

class Pet(Base):
    __tablename__ = "pet"

    pet_id = Column(Integer, primary_key=True, index=True)
    species_id = Column(Integer, ForeignKey("species_config.species_id"), nullable=False)
    owner_id = Column(Integer, ForeignKey("owner.owner_id"), nullable=False)

    pet_first_name = Column(String(50), nullable=False)
    pet_last_name = Column(String(50))
    pet_image_path = Column(String, nullable=True)

class PetMetaData(Base):
    __tablename__ = "pet_metadata"
    meta_data_id = Column(Integer, primary_key=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)
    notes = Column(Text, nullable=False)

# METRIC DEFINITIONS & HEALTH 
class MetricName(enum.Enum):
    weight = "weight"
    stool_quality = "stool_quality"
    energy_level = "energy_level"
    appetite = "appetite"
    water_intake = "water_intake"
    litter_box_usage = "litter_box_usage"
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
    notes = "notes"
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

class MetricDefinition(Base):
    __tablename__ = "metric_definition"
    metric_def_id = Column(Integer, primary_key=True, nullable=False, index=True)
    species_id = Column(Integer, ForeignKey("species_config.species_id"), nullable=False, index=True)
    metric_name = Column(Enum(MetricName, name="metric_name"), nullable=False, index=True)
    metric_unit = Column(Enum(MetricUnit, name="metric_unit"), nullable=False)
    notes = Column(Text)

class HealthMetric(Base):
    __tablename__ = "health_metric"
    health_metric_id = Column(Integer, primary_key=True, nullable=False, index=True)
    metric_def_id = Column(Integer, ForeignKey("metric_definition.metric_def_id"), nullable=False, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)
    metric_value = Column(Numeric)
    metric_time = Column(DateTime, nullable=False, index=True)
    notes = Column(Text, nullable=True)

class AppointmentStatus(enum.Enum):
    Scheduled = "Scheduled"
    Completed = "Completed"
    Cancelled = "Cancelled"

class AppointmentReminderFrequency(enum.Enum):
    once = "once"
    weekly = "weekly"
    monthly = "monthly"
    none = "none"

class PetAppointment(Base):
    __tablename__ = "pet_appointment"

    pet_appointment_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)

    series_id = Column(Integer, nullable=True, index=True)
    enable_reminder = Column(Boolean, nullable=False, default=True)
    reminder_frequency = Column(Enum(AppointmentReminderFrequency, name="reminder_frequency") ,nullable=False, default=AppointmentReminderFrequency.once)
    pet_appointment_date = Column(Date, nullable=False, index=True)
    pet_appointment_time = Column(Time, nullable=False, index=True)
    appointment_status = Column(Enum(AppointmentStatus, name="appointment_status"), nullable=False, default=AppointmentStatus.Scheduled)
    appointment_notes = Column(Text, nullable=True) # For the Fake Vet notes

class FeedingSchedule(Base):
    __tablename__ = "feeding_schedule"

    feeding_schedule_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)
    feeding_schedule_start = Column(Date, nullable=False, index=True)
    feeding_schedule_end = Column(Date, nullable=False, index=True)
    feeding_time = Column(DateTime, nullable=False)
    portion_size = Column(Integer, nullable=False)
    food_name = Column(String(100), nullable=False)

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
    reminder_datetime = Column(DateTime, nullable=False, index=True)
    reminder_status = Column(Enum(ReminderStatus, name="reminder_status"), nullable=False, default=ReminderStatus.pending)
    reminder_notes = Column(Text)

class PetGoal(Base):
    __tablename__ = "pet_goal"

    pet_goal_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)
    metric_def_id = Column(Integer, ForeignKey("metric_definition.metric_def_id"), nullable=False)
    target_value = Column(String(50), nullable=True) 
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    pet = relationship("Pet", backref="goals")
    metric_definition = relationship("MetricDefinition")

class ReportFrequency(enum.Enum):
    weekly = "weekly"
    monthly = "monthly"

class PetReport(Base):
    __tablename__ = "pet_report"

    pet_report_id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pet.pet_id"), nullable=False, index=True)
    report_frequency = Column(Enum(ReportFrequency, name="report_frequency"), nullable=False, index=True)
    report_date = Column(DateTime, nullable=False, index=True)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    report_summary = Column(Text, nullable=False)  # JSON serialized summary of metrics
    has_risk_flags = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
