from sqlalchemy.orm import Session
from petsync_backend.database import SessionLocal, engine, Base
from petsync_backend.models import (
    Species_config, MetricDefinition, MetricName, 
    MetricUnit, SpeciesType, Owner, Pet, HealthMetric
)
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
    # Expanded to include two distinct breeds for each category
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
        existing = db.query(Species_config).filter(
            Species_config.breed_name == item["breed"]
        ).first()
        
        if not existing:
            species = Species_config(
                species_name=item["type"], 
                breed_name=item["breed"], 
                notes=item["notes"]
            )
            db.add(species)
            db.commit()
            db.refresh(species)
            species_objects.append(species)
        else:
            species_objects.append(existing)

    print("Seeding Metric Definitions for ALL 12 Species...")
    unit_mapping = {
        MetricName.weight: MetricUnit.kg,
        MetricName.water_intake: MetricUnit.ml,
        MetricName.humidity_level: MetricUnit.percent,
        MetricName.stool_quality: MetricUnit.scale_1_5,
        MetricName.energy_level: MetricUnit.scale_1_5,
        MetricName.appetite: MetricUnit.scale_1_5,
        MetricName.vocalisation_level: MetricUnit.scale_1_5,
        MetricName.wheel_activity: MetricUnit.minutes_day,
        MetricName.basking_time: MetricUnit.minutes_day,
        MetricName.litter_box_usage: MetricUnit.count_day,
        MetricName.vomit_events: MetricUnit.count_day,
        MetricName.stool_pellets: MetricUnit.count_day,
        MetricName.grooming_frequency: MetricUnit.count_day,
    }

    # This loop now covers all 12 breed variations
    for s_obj in species_objects:
        for m_name in MetricName:
            if m_name in [MetricName.notes, MetricName.custom]:
                continue

            exists = db.query(MetricDefinition).filter(
                MetricDefinition.species_id == s_obj.species_id,
                MetricDefinition.metric_name == m_name
            ).first()

            if not exists:
                unit = unit_mapping.get(m_name, MetricUnit.text)
                definition = MetricDefinition(
                    species_id=s_obj.species_id,
                    metric_name=m_name,
                    metric_unit=unit
                )
                db.add(definition)

    print("Seeding Pets...")
    # Bentley (Labrador Dog)
    lab_species = db.query(Species_config).filter(Species_config.breed_name == "Labrador").first()
    if lab_species:
        if not db.query(Pet).filter(Pet.pet_first_name == "Bentley").first():
            db.add(Pet(
                pet_first_name="Bentley", pet_last_name="Coppin",
                species_id=lab_species.species_id, owner_id=owner_id, 
                pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London"
            ))

    # Maisie (Maine Coon Cat)
    coon_species = db.query(Species_config).filter(Species_config.breed_name == "Maine Coon").first()
    if coon_species:
        if not db.query(Pet).filter(Pet.pet_first_name == "Maisie").first():
            db.add(Pet(
                pet_first_name="Maisie", pet_last_name="Coppin",
                species_id=coon_species.species_id, owner_id=owner_id,
                pet_address1="123 Pet Lane", pet_postcode="PO1 2AB", pet_city="London"
            ))
    
    db.commit() # Commit Pets and Definitions first so they have IDs
    
    print("Generating Extended Health History...")
    
    # 1. BENTLEY
    bentley = db.query(Pet).filter(Pet.pet_first_name == "Bentley").first()
    if bentley:
        # We find the definition ID specifically for Bentley's species
        b_weight_def = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == bentley.species_id,
            MetricDefinition.metric_name == MetricName.weight
        ).first()

        if b_weight_def:
            print(f"DEBUG: Linking Bentley (ID: {bentley.pet_id}) to Weight Def (ID: {b_weight_def.metric_def_id})")
            history = [
                (30, 15.0), (28, 15.2), (25, 15.1), 
                (14, 11.0), (12, 10.5), (10, 10.0), 
                (5, 11.5), (2, 12.0), (0, 12.8)
            ]
            for days_back, val in history:
                log = HealthMetric(
                    pet_id=bentley.pet_id,
                    metric_def_id=b_weight_def.metric_def_id,
                    metric_value=val,
                    metric_time=datetime.utcnow() - timedelta(days=days_back)
                )
                db.add(log)
        else:
            print("DEBUG: Could not find Weight Definition for Bentley")

    # 2. MAISIE
    maisie = db.query(Pet).filter(Pet.pet_first_name == "Maisie").first()
    if maisie:
        m_water_def = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == maisie.species_id,
            MetricDefinition.metric_name == MetricName.water_intake
        ).first()

        if m_water_def:
            print(f"DEBUG: Linking Maisie (ID: {maisie.pet_id}) to Water Def (ID: {m_water_def.metric_def_id})")
            for i in range(30, -1, -5):
                log = HealthMetric(
                    pet_id=maisie.pet_id,
                    metric_def_id=m_water_def.metric_def_id,
                    metric_value=250.0 + (i % 10),
                    metric_time=datetime.utcnow() - timedelta(days=i)
                )
                db.add(log)

    db.commit() # Final commit for all health logs
    
    # Final Verification Print
    total_logs = db.query(HealthMetric).count()
    print(f"📈 Total Health Logs Seeded: {total_logs}")
    
    db.close()
    print("✅ Database Seeded with 12 species configurations!")

if __name__ == "__main__":
    seed_data()