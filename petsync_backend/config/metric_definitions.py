from sqlalchemy.orm import Session
from petsync_backend.models import MetricDefinition, MetricName, MetricUnit

UNIT_MAPPING = {
    MetricName.weight: MetricUnit.kg,
    MetricName.water_intake: MetricUnit.ml,
    MetricName.humidity_level: MetricUnit.percent,
    MetricName.stool_quality: MetricUnit.scale_1_5,
    MetricName.energy_level: MetricUnit.scale_1_5,
    MetricName.appetite: MetricUnit.scale_1_5,
    MetricName.litter_box_usage: MetricUnit.count_day,
    MetricName.grooming_frequency: MetricUnit.count_day,
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

SKIP_METRICS = {MetricName.notes, MetricName.custom}


def seed_metric_definitions(db: Session, species_objects: list) -> None:
    print("Seeding Metric Definitions...")
    for s_obj in species_objects:
        for m_name in MetricName:
            if m_name in SKIP_METRICS:
                continue
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
