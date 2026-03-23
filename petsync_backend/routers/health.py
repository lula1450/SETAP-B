from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from petsync_backend.database import get_db
from petsync_backend.models import HealthMetric, MetricDefinition, MetricName, MetricUnit, Pet
from pydantic import BaseModel, Field
from typing import Optional, Union


router = APIRouter(
    prefix="",
    tags=["Health"]
)

# SCHEMAS
class HealthMetricLogCreate(BaseModel):
    pet_id: int = Field(..., gt=0)
    metric_name: MetricName
    value: Union[float, int, str]
    notes: Optional[str] = Field(None, max_length=1000)

class HealthMetricLogResponse(BaseModel):
    status: str
    analysis: str

# ROUTES
@router.post("/log", response_model=HealthMetricLogResponse)
async def log_health_metric(log: HealthMetricLogCreate, db: Session = Depends(get_db)):
    # Fetch pet first to get species_id for the metric definition check
    pet = db.query(Pet).filter(Pet.pet_id == log.pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found.")

    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.metric_name == log.metric_name,
        MetricDefinition.species_id == pet.species_id
    ).first()
    
    if not metric_def:
        raise HTTPException(status_code=404, detail="Metric type not defined for this species.")

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

    analysis = await analyze_health_metric(
        log.pet_id, 
        log.metric_name, 
        metric_val_to_save, # Use the parsed float
        metric_def, # Pass the whole definition object
        db
    )
    
    return {"status": "Logged", "analysis": analysis}

async def analyze_health_metric(pet_id, metric_name, current_value, metric_def, db):
    unit = metric_def.metric_unit
    
    # Text Analysis
    if unit == MetricUnit.text:
        val_str = str(current_value).lower()
        keywords = ["abnormal", "poor", "lethargic", "blood", "diarrhea"]
        if any(word in val_str for word in keywords):
            return "ALERT: Potential health issue detected based on notes."
        return "No concerning keywords detected."

    # Goal Analysis (Comparing current to target)
    if metric_def.target_value:
        try:
            target = float(metric_def.target_value)
            if metric_name == MetricName.weight and current_value > target:
                return f"Notice: Snuggles is currently {round(current_value - target, 2)}kg over target."
        except ValueError:
            pass # Target wasn't a number

    # Fetch previous for baseline
    previous = db.query(HealthMetric).filter(
            HealthMetric.pet_id == pet_id,
            HealthMetric.metric_def_id == metric_def.metric_def_id
    ).order_by(HealthMetric.metric_time.desc()).offset(1).first()

    if not previous:
        return "Baseline established."

    previous_value = float(previous.metric_value)

    # Comparison Logic
    if metric_name == MetricName.weight:
        diff = abs(current_value - previous_value) / (previous_value if previous_value != 0 else 1)
        if diff >= 0.15:
            return f"ALERT: Significant weight change ({round(diff * 100, 1)}%) detected."
        return "Weight stable."
    
    # ... (Keep your other elifs for energy, water, etc. using current_value and previous_value)
    
    return f"Change from last record: {round(current_value - previous_value, 2)} {unit.value}."

# petsync_backend/routers/health.py

@router.get("/latest")
def get_latest_metric(pet_id: int, metric_name: str, db: Session = Depends(get_db)):
    # 1. Find the pet's species
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")

    # 2. Find the metric definition
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == metric_name
    ).first()

    # SAFE CHECK: If the metric doesn't exist for this species, return a placeholder
    if not metric_def:
        return {"value": "N/A", "unit": ""}

    # 3. Find the latest log
    latest_log = db.query(HealthMetric).filter(
        HealthMetric.pet_id == pet_id,
        HealthMetric.metric_def_id == metric_def.metric_def_id # This line used to crash
    ).order_by(HealthMetric.timestamp.desc()).first()

    if not latest_log:
        return {"value": "---", "unit": metric_def.metric_unit}

    return {"value": latest_log.value, "unit": metric_def.metric_unit}

@router.post("/goal")
def set_metric_goal(pet_id: int, metric_name: str, goal: str, db: Session = Depends(get_db)):
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail="Pet not found")
        
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == metric_name
    ).first()

    if not metric_def:
        raise HTTPException(status_code=404, detail="Metric definition not found")

    metric_def.target_value = goal
    db.commit()
    return {"status": "success", "message": "Goal updated."}