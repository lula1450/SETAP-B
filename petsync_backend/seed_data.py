from sqlalchemy.orm import Session
from petsync_backend.database import SessionLocal, engine
from petsync_backend.models import Base, Species_config, MetricDefinition, MetricName, MetricUnit, SpeciesType

def seed_data():
    db: Session = SessionLocal()
    
    # 1. OPTIONAL: Clear existing data to avoid 'Unique Constraint' errors
    # Base.metadata.drop_all(bind=engine) # Uncomment if you want a TOTAL reset
    # Base.metadata.create_all(bind=engine)

    print("Seeding Species...")
    
    # Note: 'type' must match the EXACT values in your SpeciesType Enum in models.py
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
        # Check if already exists to prevent duplicates
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
        s_type = s_obj.species_name # This is now an Enum object

        # Match based on the Enum value
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
        # Add other elifs here for bird, snake, etc.

    for m in metric_defs:
        # Check if definition already exists for this species
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
    
    db.commit()
    db.close()
    print("✅ Database Seeded successfully!")

if __name__ == "__main__":
    seed_data()