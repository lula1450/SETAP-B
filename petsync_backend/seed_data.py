from sqlalchemy.orm import Session
from petsync_backend.database import SessionLocal, engine, Base
from petsync_backend.models import (
    Species_config, MetricDefinition, MetricName, 
    MetricUnit, SpeciesType, Owner, Pet # Added Pet here
)

def seed_data():
    # 1. Create tables if they don't exist
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    print("Seeding Owners...")
    existing_owner = db.query(Owner).filter(Owner.owner_email == "test@petsync.com").first()
    
    if not existing_owner:
        new_owner = Owner(
            owner_first_name="Lauren",
            owner_last_name="Coppin",
            owner_email="test@petsync.com", # Use this in your Flutter Login
            password="password123",
            owner_phone_number="07123456789",
            owner_address1="123 Pet Lane",
            owner_postcode="PO1 2AB",
            owner_city="Portsmouth"
        )
        db.add(new_owner)
        db.commit()
        db.refresh(new_owner)
        owner_id = new_owner.owner_id
    else:
        owner_id = existing_owner.owner_id
        
    print("Seeding Species...")
    species_data = [ 
        {"type": SpeciesType.dog, "breed": "Labrador", "notes": "Monitor joints"},
        {"type": SpeciesType.cat, "breed": "Maine Coon", "notes": "Heart health"},
        {"type": SpeciesType.rabbit, "breed": "Holland Lop", "notes": "Dental health"},
        {"type": SpeciesType.hamster, "breed": "Syrian", "notes": "Wheel focus"},
        {"type": SpeciesType.bird, "breed": "African Grey", "notes": "Plumage care"},
        {"type": SpeciesType.snake, "breed": "Corn Snake", "notes": "Shedding focus"}
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

    print("Seeding Metric Definitions...")
    metric_defs = []
    for s_obj in species_objects:
        s_id = s_obj.species_id
        s_type = s_obj.species_name 

        if s_type == SpeciesType.dog:
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.kg},
                {"s_id": s_id, "name": MetricName.energy_level, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.appetite, "unit": MetricUnit.scale_1_5}
            ])
        elif s_type == SpeciesType.cat:
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.kg},
                {"s_id": s_id, "name": MetricName.litter_box_usage, "unit": MetricUnit.count_day},
                {"s_id": s_id, "name": MetricName.vomit_events, "unit": MetricUnit.text}
            ])

    for m in metric_defs:
        exists = db.query(MetricDefinition).filter(
            MetricDefinition.species_id == m["s_id"],
            MetricDefinition.metric_name == m["name"]
        ).first()
        if not exists:
            definition = MetricDefinition(
                species_id=m["s_id"],
                metric_name=m["name"],
                metric_unit=m["unit"]
            )
            db.add(definition)

    print("Seeding Pets...")
    # Grab the Labrador species specifically for Snuggles
    dog_species = db.query(Species_config).filter(Species_config.species_name == SpeciesType.dog).first()

    if dog_species:
        if not db.query(Pet).filter(Pet.pet_first_name == "Bentley").first():
            snuggles = Pet(
                pet_first_name="Bentley",
                species_id=dog_species.species_id,
                owner_id=owner_id, 
                pet_address1="123 Pet Lane",
                pet_postcode="PO1 2AB",
                pet_city="Portsmouth"
            )
            db.add(snuggles) # Now Snuggles is added correctly!
    
    # Final Commit to save EVERYTHING
    db.commit()
    db.close()
    print("✅ Database Seeded successfully!")

if __name__ == "__main__":
    seed_data()