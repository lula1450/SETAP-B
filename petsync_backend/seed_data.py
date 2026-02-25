# This script seeds the database with initial species configurations and their associated metric definitions.

from sqlalchemy.orm import Session
from database import SessionLocal
from models import Species_config, MetricDefinition, MetricName, MetricUnit

def seed_data():
    db: Session = SessionLocal()
    
    species_data = [ 
        {"type": "Dog", "breed": "Labrador", "notes": "Monitor joints"},
        {"type": "Dog", "breed": "French Bulldog", "notes": "Respiratory care"},
        {"type": "Cat", "breed": "Maine Coon", "notes": "Large breed heart health"},
        {"type": "Cat", "breed": "Siamese", "notes": "Vocal monitoring"},
        {"type": "Rabbit", "breed": "Holland Lop", "notes": "Dental health"},
        {"type": "Rabbit", "breed": "Netherland Dwarf", "notes": "Digestive sensitivity"},
        {"type": "Hamster", "breed": "Syrian", "notes": "Wheel activity focus"},
        {"type": "Hamster", "breed": "Roborovski", "notes": "High exercise needs"},
        {"type": "Bird", "breed": "African Grey", "notes": "Intelligent plumage care"},
        {"type": "Bird", "breed": "Budgie", "notes": "Social vocalisation"},
        {"type": "Reptile", "breed": "Bearded Dragon", "notes": "Basking requirements"},
        {"type": "Reptile", "breed": "Leopard Gecko", "notes": "Shedding focus"}
    ]

    species_objects = [] # Keep track of created species for metric association
    for item in species_data:
        species = Species_config(
            species_name=item["type"], 
            breed_name=item["breed"], 
            notes=item["notes"]
        )
        db.add(species)
        species_objects.append(species)
    
    db.commit() # Save to generate IDs

    metric_defs = []

    for s_obj in species_objects:
        s_id = s_obj.species_id
        s_type = s_obj.species_name

        if s_type == "Dog":
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.kg},
                {"s_id": s_id, "name": MetricName.stool_quality, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.energy_level, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.appetite, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.water_intake, "unit": MetricUnit.ml}
            ])
        elif s_type == "Cat":
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.kg},
                {"s_id": s_id, "name": MetricName.litter_box_usage, "unit": MetricUnit.count_day},
                {"s_id": s_id, "name": MetricName.grooming_frequency, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.vomit_events, "unit": MetricUnit.text},
                {"s_id": s_id, "name": MetricName.appetite, "unit": MetricUnit.scale_1_5}
            ])
        elif s_type == "Bird":
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.grams},
                {"s_id": s_id, "name": MetricName.feather_condition, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.wing_strength, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.perch_activity, "unit": MetricUnit.minutes_day},
                {"s_id": s_id, "name": MetricName.vocalisation_level, "unit": MetricUnit.scale_1_5}
            ])
        elif s_type == "Reptile":
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.grams},
                {"s_id": s_id, "name": MetricName.basking_time, "unit": MetricUnit.minutes_day},
                {"s_id": s_id, "name": MetricName.shedding_quality, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.appetite, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.humidity_level, "unit": MetricUnit.percent}
            ])
        elif s_type == "Rabbit":
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.kg},
                {"s_id": s_id, "name": MetricName.stool_pellets, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.chewing_behaviour, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.water_intake, "unit": MetricUnit.ml},
                {"s_id": s_id, "name": MetricName.energy_level, "unit": MetricUnit.scale_1_5}
            ])
        elif s_type == "Hamster":
            metric_defs.extend([
                {"s_id": s_id, "name": MetricName.weight, "unit": MetricUnit.grams},
                {"s_id": s_id, "name": MetricName.wheel_activity, "unit": MetricUnit.minutes_day},
                {"s_id": s_id, "name": MetricName.appetite, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.grooming_frequency, "unit": MetricUnit.scale_1_5},
                {"s_id": s_id, "name": MetricName.stool_quality, "unit": MetricUnit.scale_1_5}
            ])

    for m in metric_defs:
        definition = MetricDefinition(
            species_id=m["s_id"],
            metric_name=m["name"],
            metric_unit=m["unit"]
        )
        db.add(definition)
    
    db.commit()
    db.close()
    print("Database Seeded with species-specific metrics!")

if __name__ == "__main__":
    seed_data()