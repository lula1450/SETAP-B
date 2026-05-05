from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from petsync_backend.database import get_db
from petsync_backend.models import HealthMetric, MetricDefinition, MetricName, MetricUnit, Pet, PetGoal
from petsync_backend import schemas

router = APIRouter(
    prefix="",
    tags=["Health"]
)

# --- 1. ANALYZE HELPER (Used by the Log route) ---

async def analyze_health_metric(pet_id, metric_name, current_value, metric_def, db):
    # Cache the unit immediately before any session issues
    unit = metric_def.metric_unit
    
    if unit == MetricUnit.text:
        val_str = str(current_value).lower()
        keywords = ["abnormal", "poor", "lethargic", "blood", "diarrhea"]
        if any(word in val_str for word in keywords):
            return "ALERT: Potential health issue detected based on notes."
        return "No concerning keywords detected."

    # Look for the specific goal for THIS pet in the NEW table
    goal_record = db.query(PetGoal).filter(
        PetGoal.pet_id == pet_id,
        PetGoal.metric_def_id == metric_def.metric_def_id
    ).first()

    analysis_prefix = ""
    if goal_record and goal_record.target_value:
        try:
            target = float(goal_record.target_value)
            if metric_name == MetricName.weight:
                if current_value > target:
                    analysis_prefix = f"Notice: Currently {round(current_value - target, 2)}kg over target. "
                elif current_value < target:
                    analysis_prefix = f"Notice: Currently {round(target - current_value, 2)}kg under target. "
        except ValueError:
            pass 

    # Fetch previous for baseline (Fixed column name to metric_time)
    previous = db.query(HealthMetric).filter(
            HealthMetric.pet_id == pet_id,
            HealthMetric.metric_def_id == metric_def.metric_def_id
    ).order_by(HealthMetric.metric_time.desc()).offset(1).first()

    if not previous:
        return f"{analysis_prefix}Baseline established.".strip()

    previous_value = float(previous.metric_value)

    if metric_name == MetricName.weight:
        diff = abs(current_value - previous_value) / (previous_value if previous_value != 0 else 1)
        if diff >= 0.15:
            return f"{analysis_prefix}ALERT: Significant weight change ({round(diff * 100, 1)}%) detected."
        return f"{analysis_prefix}Weight stable."
    
    return f"{analysis_prefix}Change: {round(current_value - previous_value, 2)} {unit.value}."

# --- 3. ROUTES ---

@router.get("/metrics/{pet_id}")
def get_available_metrics(pet_id: int, db: Session = Depends(get_db)):
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    definitions = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id
    ).all()
    return [{"name": d.metric_name.value, "unit": d.metric_unit.value} for d in definitions]

@router.post("/log", response_model=schemas.HealthMetricLogResponse)
async def log_health_metric(log: schemas.HealthMetricLogCreate, db: Session = Depends(get_db)):
    pet = db.query(Pet).filter(Pet.pet_id == log.pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found.")
    
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.metric_name == log.metric_name,
        MetricDefinition.species_id == pet.species_id
    ).first()
    
    if not metric_def:
        raise HTTPException(status_code=404, detail=f"Metric type '{log.metric_name}' not defined for this species.")

    metric_val_to_save = 0
    notes_to_save = log.notes

    if metric_def.metric_unit == MetricUnit.text:
        notes_to_save = str(log.value)
    else:
        try:
            metric_val_to_save = float(log.value)
        except ValueError:
            return {"status": "Error", "analysis": "ERROR: Quantitative metric received non-numeric value."}

    new_log = HealthMetric(
        pet_id=log.pet_id,
        metric_def_id=metric_def.metric_def_id,
        metric_value=metric_val_to_save,
        metric_time=datetime.utcnow(),
        notes=notes_to_save
    )
    db.add(new_log)
    db.commit() 
    db.refresh(new_log)

    # Re-query the metric_def to ensure it's attached to the session for analysis
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.metric_def_id == metric_def.metric_def_id
    ).first()

    analysis = await analyze_health_metric(
        log.pet_id, 
        log.metric_name, 
        metric_val_to_save, 
        metric_def, 
        db
    )
    
    return {"status": "Logged", "analysis": analysis}

@router.get("/latest")
def get_latest_metric(pet_id: int, metric_name: str, db: Session = Depends(get_db)):
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == MetricName(metric_name)
    ).first()

    if not metric_def:
        return {"value": "N/A", "unit": ""}

    latest_log = db.query(HealthMetric).filter(
        HealthMetric.pet_id == pet_id,
        HealthMetric.metric_def_id == metric_def.metric_def_id
    ).order_by(HealthMetric.metric_time.desc()).first()

    goal_record = db.query(PetGoal).filter(
        PetGoal.pet_id == pet_id,
        PetGoal.metric_def_id == metric_def.metric_def_id
    ).first()

    return {
        "value": float(latest_log.metric_value) if latest_log and latest_log.metric_value is not None else "---",
        "unit": metric_def.metric_unit.value,
        "target": goal_record.target_value if goal_record else "",
        "time": latest_log.metric_time.strftime("%d %b %Y, %H:%M") if latest_log and latest_log.metric_time else "",
        "id": latest_log.health_metric_id if latest_log else None,
    }

@router.post("/goal")
def set_metric_goal(pet_id: int, metric_name: str, goal: str, db: Session = Depends(get_db)):
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
        
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == MetricName(metric_name)
    ).first()

    if not metric_def:
        raise HTTPException(status_code=404, detail="Metric definition not found")

    existing_goal = db.query(PetGoal).filter(
        PetGoal.pet_id == pet_id,
        PetGoal.metric_def_id == metric_def.metric_def_id
    ).first()

    if existing_goal:
        existing_goal.target_value = goal
    else:
        new_goal = PetGoal(
            pet_id=pet_id,
            metric_def_id=metric_def.metric_def_id,
            target_value=goal
        )
        db.add(new_goal)

    db.commit()
    return {"status": "success", "message": f"Goal updated for {metric_name}."}

@router.delete("/all/{pet_id}/{metric_name}")
def delete_all_entries(pet_id: int, metric_name: str, db: Session = Depends(get_db)):
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == MetricName(metric_name)
    ).first()
    if not metric_def:
        raise HTTPException(status_code=404, detail="Metric definition not found")
    db.query(HealthMetric).filter(
        HealthMetric.pet_id == pet_id,
        HealthMetric.metric_def_id == metric_def.metric_def_id
    ).delete()
    db.commit()
    return {"status": "deleted"}

@router.delete("/goal/{pet_id}/{metric_name}")
def delete_metric_goal(pet_id: int, metric_name: str, db: Session = Depends(get_db)):
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == MetricName(metric_name)
    ).first()
    if not metric_def:
        raise HTTPException(status_code=404, detail="Metric definition not found")
    goal = db.query(PetGoal).filter(
        PetGoal.pet_id == pet_id,
        PetGoal.metric_def_id == metric_def.metric_def_id
    ).first()
    if goal:
        db.delete(goal)
        db.commit()
    return {"status": "deleted"}

@router.delete("/history/entry/{pet_id}/{metric_id}")
def delete_health_entry(pet_id: int, metric_id: int, db: Session = Depends(get_db)):
    entry = db.query(HealthMetric).filter(
        HealthMetric.health_metric_id == metric_id,
        HealthMetric.pet_id == pet_id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Log entry not found")
    db.delete(entry)
    db.commit()
    return {"status": "deleted"}

@router.get("/history/{pet_id}")
async def get_pet_history(pet_id: int, db: Session = Depends(get_db)):
    # Join HealthMetric with MetricDefinition to get the name and unit
    history = db.query(
        HealthMetric.health_metric_id,
        HealthMetric.metric_value,
        HealthMetric.metric_time,
        MetricDefinition.metric_name,
        MetricDefinition.metric_unit
    ).join(MetricDefinition, HealthMetric.metric_def_id == MetricDefinition.metric_def_id) \
     .filter(HealthMetric.pet_id == pet_id) \
     .order_by(HealthMetric.metric_time.desc()) \
     .all()

    # Format it for the Flutter list
    return [
        {
            "id": h.health_metric_id,
            "metric": h.metric_name.value if hasattr(h.metric_name, 'value') else str(h.metric_name),
            "value": h.metric_value,
            "unit": h.metric_unit.value if hasattr(h.metric_unit, 'value') else str(h.metric_unit),
            "time": h.metric_time.strftime("%d %b %Y, %H:%M")
        } for h in history
    ]

