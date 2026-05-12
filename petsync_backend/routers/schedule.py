from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, date
from dateutil.relativedelta import relativedelta
from typing import List

from petsync_backend import models, schemas
from petsync_backend.database import get_db
from petsync_backend.utils.auth_utils import get_current_owner_id

router = APIRouter(
    prefix="",
    tags=["Scheduling & Reminders"]
)


def _require_pet_owner(pet_id: int, current_owner_id: int, db: Session) -> models.Pet:
    pet = db.query(models.Pet).filter(models.Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    if pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return pet


def _require_owner_for_appt(appointment_id: int, current_owner_id: int, db: Session) -> models.PetAppointment:
    appointment = db.query(models.PetAppointment).filter(
        models.PetAppointment.pet_appointment_id == appointment_id
    ).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    pet = db.query(models.Pet).filter(models.Pet.pet_id == appointment.pet_id).first()
    if not pet or pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return appointment


def _require_owner_for_reminder(reminder_id: int, current_owner_id: int, db: Session) -> models.Reminder:
    reminder = db.query(models.Reminder).filter(models.Reminder.reminder_id == reminder_id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
    pet = None
    if reminder.pet_appointment_id:
        appt = db.query(models.PetAppointment).filter(
            models.PetAppointment.pet_appointment_id == reminder.pet_appointment_id
        ).first()
        if appt:
            pet = db.query(models.Pet).filter(models.Pet.pet_id == appt.pet_id).first()
    elif reminder.feeding_schedule_id:
        sched = db.query(models.FeedingSchedule).filter(
            models.FeedingSchedule.feeding_schedule_id == reminder.feeding_schedule_id
        ).first()
        if sched:
            pet = db.query(models.Pet).filter(models.Pet.pet_id == sched.pet_id).first()
    if not pet or pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return reminder


@router.post("/appointments", status_code=status.HTTP_201_CREATED)
def create_pet_appointment(
    appointment: schemas.AppointmentCreate,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    _require_pet_owner(appointment.pet_id, current_owner_id, db)
    try:
        freq = models.AppointmentReminderFrequency[appointment.reminder_frequency]
    except KeyError:
        freq = models.AppointmentReminderFrequency.once

    # Build a list of date offsets so recurring appointments can be bulk-created
    # in one request (4 weeks for weekly, 12 months for monthly, 1 for once/none).
    if freq == models.AppointmentReminderFrequency.weekly:
        deltas = [timedelta(weeks=i) for i in range(4)]
    elif freq == models.AppointmentReminderFrequency.monthly:
        deltas = [relativedelta(months=i) for i in range(12)]
    else:
        deltas = [timedelta(0)]

    first_appointment = None
    all_appointments = []
    for delta in deltas:
        appt_date = appointment.appointment_date + delta
        new_appointment = models.PetAppointment(
            pet_id=appointment.pet_id,
            pet_appointment_date=appt_date,
            pet_appointment_time=appointment.appointment_time,
            appointment_status=models.AppointmentStatus.Scheduled,
            appointment_notes=appointment.notes,
            enable_reminder=freq != models.AppointmentReminderFrequency.none,
            reminder_frequency=freq,
        )
        db.add(new_appointment)
        db.flush()

        if freq != models.AppointmentReminderFrequency.none:
            appt_dt = datetime.combine(appt_date, appointment.appointment_time)
            db.add(models.Reminder(
                pet_appointment_id=new_appointment.pet_appointment_id,
                reminder_datetime=appt_dt - timedelta(hours=24),
                reminder_notes="Upcoming vet appointment",
            ))

        if first_appointment is None:
            first_appointment = new_appointment
        all_appointments.append(new_appointment)

    # Link recurring appointments together so they can be deleted as a series.
    series_id = first_appointment.pet_appointment_id if len(all_appointments) > 1 else None
    for appt in all_appointments:
        appt.series_id = series_id

    db.commit()
    return first_appointment


@router.post("/feeding-schedules", status_code=status.HTTP_201_CREATED)
def create_feeding_schedule(
    schedule: schemas.FeedingScheduleCreate,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    _require_pet_owner(schedule.pet_id, current_owner_id, db)
    feeding_dt = datetime.combine(date.today(), schedule.feeding_time)
    new_schedule = models.FeedingSchedule(
        pet_id=schedule.pet_id,
        feeding_schedule_start=date.today(),
        feeding_schedule_end=date.today() + timedelta(days=365),
        feeding_time=feeding_dt,
        portion_size=0,
        food_name=schedule.food_type,
    )
    db.add(new_schedule)
    db.commit()
    db.refresh(new_schedule)

    reminder_dt = datetime.combine(date.today() + timedelta(days=1), schedule.feeding_time)
    db.add(models.Reminder(
        feeding_schedule_id=new_schedule.feeding_schedule_id,
        reminder_datetime=reminder_dt,
        reminder_notes="Feeding time",
    ))
    db.commit()
    return new_schedule


@router.get("/appointments/owner/{owner_id}")
def get_all_owner_appointments(
    owner_id: int,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    owner = db.query(models.Owner).filter(models.Owner.owner_id == owner_id).first()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    if current_owner_id != owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return (
        db.query(models.PetAppointment)
        .join(models.Pet)
        .filter(models.Pet.owner_id == owner_id)
        .all()
    )


@router.get("/feeding-schedules/pet/{pet_id}")
def get_feeding_schedules(
    pet_id: int,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    _require_pet_owner(pet_id, current_owner_id, db)
    return db.query(models.FeedingSchedule).filter(models.FeedingSchedule.pet_id == pet_id).all()


@router.get("/reminders/pending/{owner_id}", response_model=List[schemas.ReminderPending])
def get_pending_reminders(
    owner_id: int,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    if current_owner_id != owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    results = []

    appt_rows = (
        db.query(models.Reminder, models.Pet)
        .join(models.PetAppointment,
              models.Reminder.pet_appointment_id == models.PetAppointment.pet_appointment_id)
        .join(models.Pet, models.PetAppointment.pet_id == models.Pet.pet_id)
        .filter(models.Pet.owner_id == owner_id)
        .filter(models.Reminder.reminder_status == models.ReminderStatus.pending)
        .all()
    )
    for reminder, pet in appt_rows:
        pet_name = pet.pet_first_name
        results.append(schemas.ReminderPending(
            reminder_id=reminder.reminder_id,
            reminder_datetime=reminder.reminder_datetime,
            type="appointment",
            pet_id=pet.pet_id,
            pet_name=pet_name,
            title=f"Vet Appointment — {pet_name}",
            body=f"{pet_name} has a vet appointment tomorrow.",
            appointment_id=reminder.pet_appointment_id,
        ))

    feeding_rows = (
        db.query(models.Reminder, models.FeedingSchedule, models.Pet)
        .join(models.FeedingSchedule,
              models.Reminder.feeding_schedule_id == models.FeedingSchedule.feeding_schedule_id)
        .join(models.Pet, models.FeedingSchedule.pet_id == models.Pet.pet_id)
        .filter(models.Pet.owner_id == owner_id)
        .filter(models.Reminder.reminder_status == models.ReminderStatus.pending)
        .all()
    )
    for reminder, schedule, pet in feeding_rows:
        pet_name = pet.pet_first_name
        # SQLite can return feeding_time as either a datetime or a time object
        # depending on how the value was stored, so we handle both.
        ft = schedule.feeding_time
        hour = ft.hour if isinstance(ft, datetime) else getattr(ft, 'hour', reminder.reminder_datetime.hour)
        minute = ft.minute if isinstance(ft, datetime) else getattr(ft, 'minute', reminder.reminder_datetime.minute)
        results.append(schemas.ReminderPending(
            reminder_id=reminder.reminder_id,
            reminder_datetime=reminder.reminder_datetime,
            type="feeding",
            pet_id=pet.pet_id,
            pet_name=pet_name,
            title=f"Feeding Time — {pet_name}",
            body=f"Time to feed {pet_name} ({schedule.food_name}).",
            feeding_schedule_id=reminder.feeding_schedule_id,
            feeding_hour=hour,
            feeding_minute=minute,
        ))

    return results


@router.put("/appointments/{appointment_id}")
def update_pet_appointment(
    appointment_id: int,
    update: schemas.AppointmentUpdate,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    appointment = _require_owner_for_appt(appointment_id, current_owner_id, db)

    appointment.pet_appointment_date = update.new_date
    appointment.pet_appointment_time = update.new_time
    appointment.appointment_notes = update.notes

    new_appt_dt = datetime.combine(update.new_date, update.new_time)
    reminder = db.query(models.Reminder).filter(
        models.Reminder.pet_appointment_id == appointment_id
    ).first()
    if reminder:
        reminder.reminder_datetime = new_appt_dt - timedelta(hours=24)
        reminder.reminder_status = models.ReminderStatus.pending

    db.commit()
    db.refresh(appointment)
    return appointment


@router.patch("/reminders/{reminder_id}/status")
def update_reminder_status(
    reminder_id: int,
    update: schemas.ReminderStatusUpdate,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    reminder = _require_owner_for_reminder(reminder_id, current_owner_id, db)
    try:
        reminder.reminder_status = models.ReminderStatus[update.status]
    except KeyError:
        raise HTTPException(status_code=400, detail=f"Invalid status '{update.status}'")
    db.commit()
    return {"reminder_id": reminder_id, "status": update.status}


@router.delete("/appointments/series/{series_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_appointment_series(
    series_id: int,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    appointments = db.query(models.PetAppointment).filter(
        models.PetAppointment.series_id == series_id
    ).all()
    if not appointments:
        raise HTTPException(status_code=404, detail="Series not found")
    pet = db.query(models.Pet).filter(models.Pet.pet_id == appointments[0].pet_id).first()
    if not pet or pet.owner_id != current_owner_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    for appt in appointments:
        db.query(models.Reminder).filter(
            models.Reminder.pet_appointment_id == appt.pet_appointment_id
        ).delete()
        db.delete(appt)
    db.commit()
    return None


@router.delete("/appointments/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_pet_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_owner_id: int = Depends(get_current_owner_id),
):
    appointment = _require_owner_for_appt(appointment_id, current_owner_id, db)
    db.query(models.Reminder).filter(
        models.Reminder.pet_appointment_id == appointment_id
    ).delete()
    db.delete(appointment)
    db.commit()
    return None
