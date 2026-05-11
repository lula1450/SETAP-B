from sqlalchemy.orm import Session
from petsync_backend.models import MetricDefinition, MetricName, MetricUnit, SpeciesType

UNIT_MAPPING = {
    MetricName.weight: MetricUnit.kg,
    MetricName.water_intake: MetricUnit.ml,
    MetricName.humidity_level: MetricUnit.percent,
    MetricName.stool_quality: MetricUnit.scale_1_5,
    MetricName.energy_level: MetricUnit.scale_1_5,
    MetricName.appetite: MetricUnit.scale_1_5,
    MetricName.litter_box_usage: MetricUnit.count_day,
    MetricName.vomit_events: MetricUnit.count_day,
    MetricName.feather_condition: MetricUnit.scale_1_5,
    MetricName.wing_strength: MetricUnit.scale_1_5,
    MetricName.perch_activity: MetricUnit.scale_1_5,
    MetricName.vocalisation_level: MetricUnit.scale_1_5,
    MetricName.basking_time: MetricUnit.minutes_day,
    MetricName.shedding_quality: MetricUnit.scale_1_5,
    MetricName.stool_pellets: MetricUnit.count_day,
    MetricName.chewing_behaviour: MetricUnit.scale_1_5,
    MetricName.wheel_activity: MetricUnit.minutes_day,
}

SPECIES_METRICS = {
    SpeciesType.dog: [
        MetricName.weight, MetricName.energy_level, MetricName.appetite,
        MetricName.water_intake, MetricName.stool_quality,
        MetricName.vomit_events,
    ],
    SpeciesType.cat: [
        MetricName.weight, MetricName.energy_level, MetricName.appetite,
        MetricName.water_intake, MetricName.stool_quality,
        MetricName.litter_box_usage, MetricName.vomit_events,
    ],
    SpeciesType.rabbit: [
        MetricName.weight, MetricName.appetite, MetricName.water_intake,
        MetricName.stool_pellets, MetricName.chewing_behaviour,
    ],
    SpeciesType.hamster: [
        MetricName.weight, MetricName.water_intake, MetricName.wheel_activity,
        MetricName.chewing_behaviour,
    ],
    SpeciesType.bird: [
        MetricName.weight, MetricName.appetite, MetricName.water_intake,
        MetricName.feather_condition, MetricName.wing_strength,
        MetricName.perch_activity, MetricName.vocalisation_level,
    ],
    SpeciesType.snake: [
        MetricName.weight, MetricName.appetite, MetricName.water_intake,
        MetricName.shedding_quality, MetricName.basking_time, MetricName.humidity_level,
    ],
}


def seed_metric_definitions(db: Session, species_objects: list) -> None:
    print("Seeding Metric Definitions...")
    for s_obj in species_objects:
        relevant = SPECIES_METRICS.get(s_obj.species_name, list(UNIT_MAPPING.keys()))
        for m_name in relevant:
            correct_unit = UNIT_MAPPING.get(m_name, MetricUnit.text)
            exists = db.query(MetricDefinition).filter(
                MetricDefinition.species_id == s_obj.species_id,
                MetricDefinition.metric_name == m_name
            ).first()
            if not exists:
                db.add(MetricDefinition(species_id=s_obj.species_id, metric_name=m_name, metric_unit=correct_unit))
            elif exists.metric_unit != correct_unit:
                exists.metric_unit = correct_unit
    db.commit()