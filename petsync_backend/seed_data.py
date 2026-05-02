import random
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, time

from petsync_backend.database import SessionLocal, engine, Base
from petsync_backend.models import (
    PetAppointment, Species_config, MetricDefinition, MetricName,
    SpeciesType, Owner, Pet, HealthMetric, ReportFrequency, PetGoal, VetContact,
    FeedingSchedule
)
from petsync_backend.config.species_data import SPECIES_DATA
from petsync_backend.config.metric_definitions import seed_metric_definitions
from petsync_backend.utils.report_generator import generate_report_for_pet

BASE_URL = "http://localhost:8000"

def seed_data():
    # 0. Clean start
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    # 1. Seed Owner
    print("Seeding Owner...")
    owner = db.query(Owner).filter(Owner.owner_email == "test@petsync.com").first()
    if not owner:
        owner = Owner(
            owner_first_name="Alex", owner_last_name="Jordan",
            owner_email="test@petsync.com", password="password123",
        )
        db.add(owner)
        db.commit()
        db.refresh(owner)
    owner_id = owner.owner_id

    # 2. Seed Species from species_data.py
    print(f"Seeding {len(SPECIES_DATA)} Breeds...")
    species_objects = []
    for item in SPECIES_DATA:
        existing = db.query(Species_config).filter(Species_config.breed_name == item["breed"]).first()
        if not existing:
            species = Species_config(species_name=item["type"], breed_name=item["breed"], notes=item["notes"])
            db.add(species)
            db.commit()
            db.refresh(species)
            species_objects.append(species)
        else:
            species_objects.append(existing)

    # 3. Seed Metric Definitions
    seed_metric_definitions(db, species_objects)

    # 4. Seed Bentley, Maisie, Rio and Ziggy
    print("Seeding Bailey, Luna, Rio and Ziggy...")
    lab_id      = db.query(Species_config).filter(Species_config.breed_name == "Labrador").first().species_id
    coon_id     = db.query(Species_config).filter(Species_config.breed_name == "Maine Coon").first().species_id
    grey_id     = db.query(Species_config).filter(Species_config.breed_name == "African Grey").first().species_id
    python_id   = db.query(Species_config).filter(Species_config.breed_name == "Ball Python").first().species_id

    bailey = db.query(Pet).filter(Pet.pet_first_name == "Bailey").first()
    if not bailey:
        bailey = Pet(pet_first_name="Bailey", pet_last_name="C", species_id=lab_id, owner_id=owner_id,
                      pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London",
                      pet_image_path=f"{BASE_URL}/static/seed_images/bailey.jpg")
        db.add(bailey)
    elif not bailey.pet_image_path:
        bailey.pet_image_path = f"{BASE_URL}/static/seed_images/bailey.jpg"

    luna = db.query(Pet).filter(Pet.pet_first_name == "Luna").first()
    if not luna:
        luna = Pet(pet_first_name="Luna", pet_last_name="C", species_id=coon_id, owner_id=owner_id,
                     pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London",
                     pet_image_path=f"{BASE_URL}/static/seed_images/luna.jpg")
        db.add(luna)
    elif not luna.pet_image_path:
        luna.pet_image_path = f"{BASE_URL}/static/seed_images/luna.jpg"

    rio = db.query(Pet).filter(Pet.pet_first_name == "Rio").first()
    if not rio:
        rio = Pet(pet_first_name="Rio", pet_last_name="C", species_id=grey_id, owner_id=owner_id,
                  pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London",
                  pet_image_path=f"{BASE_URL}/static/seed_images/rio.jpg")
        db.add(rio)
    elif not rio.pet_image_path:
        rio.pet_image_path = f"{BASE_URL}/static/seed_images/rio.jpg"

    ziggy = db.query(Pet).filter(Pet.pet_first_name == "Ziggy").first()
    if not ziggy:
        ziggy = Pet(pet_first_name="Ziggy", pet_last_name="C", species_id=python_id, owner_id=owner_id,
                    pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London",
                    pet_image_path=f"{BASE_URL}/static/seed_images/ziggy.jpg")
        db.add(ziggy)
    elif not ziggy.pet_image_path:
        ziggy.pet_image_path = f"{BASE_URL}/static/seed_images/ziggy.jpg"

    db.commit()


    print("Setting Health Targets for Bailey, Luna, Rio and Ziggy...")

    targets = [
        # Bailey Targets (Labrador)
        (bailey, MetricName.weight, 15.0),
        (bailey, MetricName.energy_level, 4.0),
        (bailey, MetricName.appetite, 4.5),

        # Luna Targets (Maine Coon)
        (luna, MetricName.weight, 6.4),
        (luna, MetricName.water_intake, 300.0),
        (luna, MetricName.stool_quality, 4.0),

        # Rio Targets (African Grey)
        (rio, MetricName.weight, 0.5),              # Goal: 500g
        (rio, MetricName.feather_condition, 4.0),   # Goal: Healthy plumage (4/5)
        (rio, MetricName.vocalisation_level, 3.0),  # Goal: Moderate (3/5)
        (rio, MetricName.appetite, 4.0),            # Goal: Good appetite (4/5)

        # Ziggy Targets (Ball Python)
        (ziggy, MetricName.weight, 1.5),            # Goal: 1.5kg
        (ziggy, MetricName.humidity_level, 60.0),   # Goal: 60% humidity
        (ziggy, MetricName.shedding_quality, 4.0),  # Goal: Clean shed (4/5)
        (ziggy, MetricName.appetite, 3.5),          # Goal: Regular feeding (3.5/5)
    ]

    for pet, m_name, target_val in targets:
        m_def = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == pet.species_id,
            MetricDefinition.metric_name == m_name
        ).first()
        if m_def:
            exists = db.query(PetGoal).filter(
                PetGoal.pet_id == pet.pet_id,
                PetGoal.metric_def_id == m_def.metric_def_id
            ).first()
            if not exists:
                db.add(PetGoal(
                    pet_id=pet.pet_id,
                    metric_def_id=m_def.metric_def_id,
                    target_value=str(target_val)
                ))
    db.commit()

    # 5. Health History Generation (60 Days / 30 Points per metric)
    print("Generating Multi-Metric Health History (60 days)...")
    scenarios = [
        # Pet, Metric, BaseValue, Variance, Trend
        (bailey, MetricName.weight,        15.0,  0.4,  "recovery"),
        (bailey, MetricName.energy_level,   4.5,  0.5,  "stable"),
        (bailey, MetricName.appetite,       4.0,  1.0,  "stable"),
        (luna,  MetricName.weight,         6.5,  0.1,  "stable"),
        (luna,  MetricName.water_intake,  280.0, 40.0, "stable"),
        (luna,  MetricName.stool_quality,  4.0,  0.5,  "stable"),
        (rio,     MetricName.weight,         0.49, 0.02, "stable"),
        (rio,     MetricName.feather_condition, 3.5, 0.4, "recovery"),
        (rio,     MetricName.vocalisation_level, 3.0, 0.5, "stable"),
        (rio,     MetricName.appetite,       3.8,  0.6,  "stable"),
        (ziggy,   MetricName.weight,         1.4,  0.05, "stable"),
        (ziggy,   MetricName.humidity_level, 58.0, 5.0,  "stable"),
        (ziggy,   MetricName.shedding_quality, 3.5, 0.5, "recovery"),
        (ziggy,   MetricName.appetite,       3.0,  0.8,  "stable"),
    ]

    METRIC_HOURS = {
        MetricName.weight:             (7, 8),
        MetricName.energy_level:       (11, 13),
        MetricName.appetite:           None,
        MetricName.water_intake:       (18, 20),
        MetricName.stool_quality:      (8, 10),
        MetricName.feather_condition:  (9, 10),
        MetricName.vocalisation_level: (10, 12),
        MetricName.humidity_level:     (12, 14),
        MetricName.shedding_quality:   (8, 10),
    }
    MEAL_HOURS = [(7, 8), (12, 13), (18, 19)]

    for pet, m_name, base, var, trend in scenarios:
        m_def = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == pet.species_id, MetricDefinition.metric_name == m_name
        ).first()
        if m_def:
            for i in range(30):
                days_back = i * 2
                if trend == "recovery":
                    if i < 10:   val = base - (i * 0.04)
                    elif i < 20: val = base - 0.4 + random.uniform(-0.05, 0.05)
                    else:        val = (base - 0.4) + ((i - 20) * 0.04)
                else:
                    val = base + random.uniform(-var, var)

                hour_range = METRIC_HOURS.get(m_name)
                h_min, h_max = hour_range if hour_range else MEAL_HOURS[i % 3]
                log_hour   = random.randint(h_min, h_max)
                log_minute = random.randint(0, 59)

                base_day = datetime.utcnow().replace(hour=log_hour, minute=log_minute, second=0, microsecond=0)
                db.add(HealthMetric(
                    pet_id=pet.pet_id, metric_def_id=m_def.metric_def_id,
                    metric_value=round(val, 2),
                    metric_time=base_day - timedelta(days=days_back)
                ))
    db.commit()


    # 6. Seed Appointments
    print("Seeding Vet Appointments...")
    today = datetime.now()

    appointments = [
        # Bentley — +2 days
        PetAppointment(
            pet_id=bailey.pet_id,
            pet_appointment_date=(today + timedelta(days=2)).date(),
            pet_appointment_time=time(10, 30),
            appointment_notes="Happy Paws Veterinary - Annual Booster Vaccinations"
        ),
        # Rio — same day as Bentley (+2 days)
        PetAppointment(
            pet_id=rio.pet_id,
            pet_appointment_date=(today + timedelta(days=2)).date(),
            pet_appointment_time=time(11, 15),
            appointment_notes="Happy Paws Veterinary - Wing and feather health check"
        ),
        # Maisie — +5 days
        PetAppointment(
            pet_id=luna.pet_id,
            pet_appointment_date=(today + timedelta(days=5)).date(),
            pet_appointment_time=time(14, 15),
            appointment_notes="Riverside Pet Clinic - Weight management follow-up and joint check"
        ),
        # Ziggy — same day as Maisie (+5 days)
        PetAppointment(
            pet_id=ziggy.pet_id,
            pet_appointment_date=(today + timedelta(days=5)).date(),
            pet_appointment_time=time(15, 30),
            appointment_notes="Riverside Pet Clinic - Shedding assessment and humidity review"
        ),
        # Bentley — +12 days
        PetAppointment(
            pet_id=bailey.pet_id,
            pet_appointment_date=(today + timedelta(days=12)).date(),
            pet_appointment_time=time(11, 0),
            appointment_notes="Happy Paws Veterinary - Flea and tick treatment"
        ),
        # Ziggy — +18 days
        PetAppointment(
            pet_id=ziggy.pet_id,
            pet_appointment_date=(today + timedelta(days=18)).date(),
            pet_appointment_time=time(9, 0),
            appointment_notes="Riverside Pet Clinic - Routine weigh-in and feeding check"
        ),
    ]

    for appt in appointments:
        exists = db.query(PetAppointment).filter(
            PetAppointment.pet_id == appt.pet_id,
            PetAppointment.pet_appointment_date == appt.pet_appointment_date
        ).first()
        if not exists:
            db.add(appt)
    db.commit()

    # 7. Seed Vet Contacts (one per pet)
    print("Seeding Vet Contacts...")
    vet_contacts = [
        VetContact(owner_id=owner_id, pet_id=bailey.pet_id,
                   clinic_name="Happy Paws Veterinary", phone="07912345678",
                   email="contact@happypaws.com", address="45 Main Street, London, SW1A 1AA"),
        VetContact(owner_id=owner_id, pet_id=luna.pet_id,
                   clinic_name="Riverside Pet Clinic", phone="02071234567",
                   email="info@riversidepet.com", address="78 River Road, London, SE1 7TP"),
        VetContact(owner_id=owner_id, pet_id=rio.pet_id,
                   clinic_name="Happy Paws Veterinary", phone="07912345678",
                   email="contact@happypaws.com", address="45 Main Street, London, SW1A 1AA"),
        VetContact(owner_id=owner_id, pet_id=ziggy.pet_id,
                   clinic_name="Riverside Pet Clinic", phone="02071234567",
                   email="info@riversidepet.com", address="78 River Road, London, SE1 7TP"),
    ]

    for vet in vet_contacts:
        exists = db.query(VetContact).filter(
            VetContact.pet_id == vet.pet_id,
            VetContact.clinic_name == vet.clinic_name
        ).first()
        if not exists:
            db.add(vet)
    db.commit()

    # 8. Seed Feeding Schedules
    print("Seeding Feeding Schedules...")
    today = datetime.now().date()
    year_end = today.replace(month=12, day=31)

    feeding_schedules = [
        # Bailey (Labrador) — 2 meals/day
        FeedingSchedule(pet_id=bailey.pet_id, food_name="Morning feed",
                        feeding_time=datetime.combine(today, time(7, 30)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=300),
        FeedingSchedule(pet_id=bailey.pet_id, food_name="Evening feed",
                        feeding_time=datetime.combine(today, time(17, 0)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=300),
        # Luna (Maine Coon) — 3 meals/day
        FeedingSchedule(pet_id=luna.pet_id, food_name="Morning feed",
                        feeding_time=datetime.combine(today, time(8, 0)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=80),
        FeedingSchedule(pet_id=luna.pet_id, food_name="Midday feed",
                        feeding_time=datetime.combine(today, time(13, 0)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=60),
        FeedingSchedule(pet_id=luna.pet_id, food_name="Evening feed",
                        feeding_time=datetime.combine(today, time(18, 0)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=80),
        # Rio (African Grey) — 2 feeds/day
        FeedingSchedule(pet_id=rio.pet_id, food_name="Morning seed mix",
                        feeding_time=datetime.combine(today, time(8, 0)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=50),
        FeedingSchedule(pet_id=rio.pet_id, food_name="Afternoon pellets & fruit",
                        feeding_time=datetime.combine(today, time(16, 0)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=40),
        # Ziggy (Ball Python) — 1 feed/week
        FeedingSchedule(pet_id=ziggy.pet_id, food_name="Weekly feeding",
                        feeding_time=datetime.combine(today, time(18, 0)),
                        feeding_schedule_start=today, feeding_schedule_end=year_end,
                        portion_size=1),
    ]

    for schedule in feeding_schedules:
        exists = db.query(FeedingSchedule).filter(
            FeedingSchedule.pet_id == schedule.pet_id,
            FeedingSchedule.food_name == schedule.food_name
        ).first()
        if not exists:
            db.add(schedule)
    db.commit()

    # 9. Trigger Automated Report Generation
    print("Creating Automated Report History...")
    for pet in [bailey, luna, rio, ziggy]:
        for freq in [ReportFrequency.weekly, ReportFrequency.monthly]:
            try:
                generate_report_for_pet(db, pet.pet_id, freq)
                print(f"✅ {freq.value.capitalize()} report ready for {pet.pet_first_name}")
            except Exception as e:
                print(f"⚠️ Report skipped for {pet.pet_first_name}: {e}")

    db.close()
    print("✅ Database Fully Seeded with 2-Month History!")

if __name__ == "__main__":
    seed_data()
