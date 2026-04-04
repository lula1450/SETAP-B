import random
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, time

from petsync_backend.database import SessionLocal, engine, Base
from petsync_backend.models import (
    PetAppointment, Species_config, MetricDefinition, MetricName, 
    MetricUnit, SpeciesType, Owner, Pet, HealthMetric, ReportFrequency, PetGoal
)
from petsync_backend.species_data import SPECIES_DATA 
from petsync_backend.utils.report_generator import generate_report_for_pet

def seed_data():
    # 0. Clean start
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    # 1. Seed Owner (Lauren)
    print("Seeding Owner...")
    owner = db.query(Owner).filter(Owner.owner_email == "test@petsync.com").first()
    if not owner:
        owner = Owner(
            owner_first_name="Lauren", owner_last_name="Coppin",
            owner_email="test@petsync.com", password="password123",
            owner_phone_number="07123456789", owner_address1="123 Pet Lane",
            owner_postcode="PO1 2AB", owner_city="London"
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
    print("Seeding Metric Definitions...")
    unit_mapping = {
        MetricName.weight: MetricUnit.kg,
        MetricName.water_intake: MetricUnit.ml,
        MetricName.humidity_level: MetricUnit.percent,
        MetricName.stool_quality: MetricUnit.scale_1_5,
        MetricName.energy_level: MetricUnit.scale_1_5,
        MetricName.appetite: MetricUnit.scale_1_5,
    }

    for s_obj in species_objects:
        for m_name in MetricName:
            if m_name in [MetricName.notes, MetricName.custom]: continue
            exists = db.query(MetricDefinition).filter(
                MetricDefinition.species_id == s_obj.species_id,
                MetricDefinition.metric_name == m_name
            ).first()
            if not exists:
                unit = unit_mapping.get(m_name, MetricUnit.text)
                db.add(MetricDefinition(species_id=s_obj.species_id, metric_name=m_name, metric_unit=unit))
    db.commit()

    # 4. Seed Bentley and Maisie
    print("Seeding Bentley and Maisie...")
    lab_id = db.query(Species_config).filter(Species_config.breed_name == "Labrador").first().species_id
    coon_id = db.query(Species_config).filter(Species_config.breed_name == "Maine Coon").first().species_id

    bentley = db.query(Pet).filter(Pet.pet_first_name == "Bentley").first()
    if not bentley:
        bentley = Pet(pet_first_name="Bentley", pet_last_name="C", species_id=lab_id, owner_id=owner_id,
                      pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London")
        db.add(bentley)
    
    maisie = db.query(Pet).filter(Pet.pet_first_name == "Maisie").first()
    if not maisie:
        maisie = Pet(pet_first_name="Maisie", pet_last_name="C", species_id=coon_id, owner_id=owner_id,
                     pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London")
        db.add(maisie)
    db.commit()


    print("Setting Health Targets for Bentley and Maisie...")
    
    # Define what "Healthy" looks like for these specific pets
    targets = [
        # Bentley Targets
        (bentley, MetricName.weight, 15.0),       # Goal: Maintain 15kg
        (bentley, MetricName.energy_level, 4.0),  # Goal: Active (4/5)
        (bentley, MetricName.appetite, 4.5),      # Goal: Hungry (4.5/5)
        
        # Maisie Targets
        (maisie, MetricName.weight, 6.4),         # Goal: Maintain 6.4kg
        (maisie, MetricName.water_intake, 300.0), # Goal: 300ml per day
        (maisie, MetricName.stool_quality, 4.0),  # Goal: Firm (4/5)
    ]

    for pet, m_name, target_val in targets:
        # Find the definition ID for this species/metric combo
        m_def = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == pet.species_id, 
            MetricDefinition.metric_name == m_name
        ).first()

        if m_def:
            # Check if target already exists
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

    # 5. Massive Health History Generation (60 Days / 30 Points per metric)
    print("Generating Multi-Metric Health History (60 days)...")
    scenarios = [
        # Pet, Metric, BaseValue, Variance, Trend
        (bentley, MetricName.weight, 15.0, 0.4, "recovery"), # Bentley's weight dip
        (bentley, MetricName.energy_level, 4.5, 0.5, "stable"),
        (bentley, MetricName.appetite, 4.0, 1.0, "stable"),
        (maisie, MetricName.weight, 6.5, 0.1, "stable"),
        (maisie, MetricName.water_intake, 280.0, 40.0, "stable"),
        (maisie, MetricName.stool_quality, 4.0, 0.5, "stable"),
    ]

    for pet, m_name, base, var, trend in scenarios:
        m_def = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == pet.species_id, MetricDefinition.metric_name == m_name
        ).first()
        if m_def:
            for i in range(30):
                days_back = i * 2
                val = base
                if trend == "recovery":
                    if i < 10: val -= (i * 0.4) # Dropping
                    elif i < 20: val = base - 4.0 + random.uniform(-0.2, 0.2) # Bottomed out
                    else: val = (base - 4.0) + ((i - 20) * 0.4) # Recovering
                else:
                    val = base + random.uniform(-var, var)

                db.add(HealthMetric(
                    pet_id=pet.pet_id, metric_def_id=m_def.metric_def_id,
                    metric_value=round(val, 2),
                    metric_time=datetime.utcnow() - timedelta(days=days_back)
                ))
    db.commit()


    # --- 5. Seed Appointments ---
    print("Seeding Vet Appointments...")
    today = datetime.now()

    appointments = [
        PetAppointment(
            pet_id=bentley.pet_id,
        # Convert to a date object
            pet_appointment_date=(today + timedelta(days=2)).date(), 
        # Convert to a time object
            pet_appointment_time=time(10, 30), 
            appointment_notes="Annual Booster Vaccinations - Dr. Smith"
        ),
        PetAppointment(
            pet_id=maisie.pet_id,
        # Convert to a date object
            pet_appointment_date=(today + timedelta(days=5)).date(),
        # Convert to a time object
             pet_appointment_time=time(14, 15),
             appointment_notes="Weight management follow-up and joint check"
        )
    ]

    for appt in appointments:
    # Check for existing to prevent duplicates
        exists = db.query(PetAppointment).filter(
            PetAppointment.pet_id == appt.pet_id,
            PetAppointment.pet_appointment_date == appt.pet_appointment_date
        ).first()
        if not exists:
            db.add(appt)
    db.commit()

    

    # 6. Trigger Automated Report Generation
    print("Creating Automated Report History...")
    for pet in [bentley, maisie]:
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