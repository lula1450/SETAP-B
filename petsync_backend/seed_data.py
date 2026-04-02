import random
from sqlalchemy.orm import Session
from petsync_backend.database import SessionLocal, engine, Base
from petsync_backend.models import (
    Species_config, MetricDefinition, MetricName, 
    MetricUnit, SpeciesType, Owner, Pet, HealthMetric, ReportFrequency
)
from petsync_backend.utils.report_generator import generate_report_for_pet
from datetime import datetime, timedelta

def seed_data():
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    print("Seeding Owners...")
    existing_owner = db.query(Owner).filter(Owner.owner_email == "test@petsync.com").first()
    
    if not existing_owner:
        new_owner = Owner(
            owner_first_name="Lauren",
            owner_last_name="Coppin",
            owner_email="test@petsync.com", 
            password="password123",
            owner_phone_number="07123456789",
            owner_address1="123 Pet Lane",
            owner_postcode="PO1 2AB",
            owner_city="London"
        )
        db.add(new_owner)
        db.commit()
        db.refresh(new_owner)
        owner_id = new_owner.owner_id
    else:
        owner_id = existing_owner.owner_id
        
    print("Seeding 2 Breeds per Animal Type...")
    species_data = [ 
        {"type": SpeciesType.dog, "breed": "Labrador", "notes": "Monitor joints"},
        {"type": SpeciesType.dog, "breed": "Golden Retriever", "notes": "High exercise needs"},
        {"type": SpeciesType.cat, "breed": "Maine Coon", "notes": "Heart health"},
        {"type": SpeciesType.cat, "breed": "Siamese", "notes": "Vocal and active"},
        {"type": SpeciesType.rabbit, "breed": "Holland Lop", "notes": "Dental health"},
        {"type": SpeciesType.rabbit, "breed": "Rex", "notes": "Velvety coat care"},
        {"type": SpeciesType.hamster, "breed": "Syrian", "notes": "Wheel focus"},
        {"type": SpeciesType.hamster, "breed": "Roborovski", "notes": "Very fast, small"},
        {"type": SpeciesType.bird, "breed": "African Grey", "notes": "Plumage care"},
        {"type": SpeciesType.bird, "breed": "Cockatiel", "notes": "Social dynamics"},
        {"type": SpeciesType.snake, "breed": "Corn Snake", "notes": "Shedding focus"},
        {"type": SpeciesType.snake, "breed": "Ball Python", "notes": "Humidity sensitive"}
    ]

    species_objects = []
    for item in species_data:
        existing = db.query(Species_config).filter(Species_config.breed_name == item["breed"]).first()
        if not existing:
            species = Species_config(species_name=item["type"], breed_name=item["breed"], notes=item["notes"])
            db.add(species)
            db.commit()
            db.refresh(species)
            species_objects.append(species)
        else:
            species_objects.append(existing)

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

    print("Seeding Pets...")
    # Get Species IDs
    lab_id = db.query(Species_config).filter(Species_config.breed_name == "Labrador").first().species_id
    coon_id = db.query(Species_config).filter(Species_config.breed_name == "Maine Coon").first().species_id

    bentley = db.query(Pet).filter(Pet.pet_first_name == "Bentley").first()
    if not bentley:
        bentley = Pet(pet_first_name="Bentley", pet_last_name="C", species_id=lab_id, owner_id=owner_id, pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London")
        db.add(bentley)
    
    maisie = db.query(Pet).filter(Pet.pet_first_name == "Maisie").first()
    if not maisie:
        maisie = Pet(pet_first_name="Maisie", pet_last_name="C", species_id=coon_id, owner_id=owner_id, pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London")
        db.add(maisie)
    
    db.commit()

    print("Generating Multi-Metric Health History...")
    
    # Define Scenarios: (Pet, Metric, BaseValue, Variance, TrendType)
    scenarios = [
        # Bentley's Data
        (bentley, MetricName.weight, 15.0, 0.2, "recovery"),
        (bentley, MetricName.appetite, 4.0, 1.0, "stable"),
        (bentley, MetricName.energy_level, 3.0, 1.0, "stable"),
        
        # Maisie's Data
        (maisie, MetricName.water_intake, 250.0, 30.0, "stable"),
        (maisie, MetricName.weight, 6.5, 0.1, "stable"),
        (maisie, MetricName.stool_quality, 4.0, 0.5, "stable"),
        (maisie, MetricName.energy_level, 4.5, 0.5, "stable"),
    ]

    for pet, m_name, base, var, trend in scenarios:
        m_def = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == pet.species_id,
            MetricDefinition.metric_name == m_name
        ).first()

        if m_def:
            print(f"DEBUG: Seeding {m_name.value} for {pet.pet_first_name}")
            # Generate 15 points over 30 days
            for i in range(15):
                days_back = i * 2
                current_val = base
                
                if trend == "recovery":
                    # Create a V-shape: drop for first 7 points, recover for next 8
                    if i < 7: current_val -= (i * 0.7)
                    else: current_val += ((i - 7) * 0.4)
                else:
                    # Random variance around the base
                    current_val = base + random.uniform(-var, var)

                db.add(HealthMetric(
                    pet_id=pet.pet_id,
                    metric_def_id=m_def.metric_def_id,
                    metric_value=round(current_val, 2),
                    metric_time=datetime.utcnow() - timedelta(days=days_back)
                ))

    db.commit()
    print(f"📈 Total Health Logs Seeded: {db.query(HealthMetric).count()}")
    
    # --- GENERATE AUTOMATED REPORTS ---
    print("Generating Automated Reports...")
    # Generate weekly and monthly reports for both pets
    for pet in [bentley, maisie]:
        try:
            # Generate weekly report
            generate_report_for_pet(db, pet.pet_id, ReportFrequency.weekly)
            print(f"✅ Weekly report generated for {pet.pet_first_name}")
            
            # Generate monthly report
            generate_report_for_pet(db, pet.pet_id, ReportFrequency.monthly)
            print(f"✅ Monthly report generated for {pet.pet_first_name}")
        except Exception as e:
            print(f"⚠️ Error generating reports for {pet.pet_first_name}: {str(e)}")
    
    db.close()
    print("✅ Database Seeded Successfully!")

if __name__ == "__main__":
    seed_data()