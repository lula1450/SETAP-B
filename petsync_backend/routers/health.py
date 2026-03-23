

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from petsync_backend.database import get_db
from petsync_backend.models import HealthMetric, MetricDefinition, MetricName, MetricUnit
from pydantic import BaseModel, Field
from typing import Optional, Union
#from petsync_backend import models, schemas

router = APIRouter(
    prefix="",
    tags=["Health"]
)

#SCHEMAS

class HealthMetricLogCreate(BaseModel):
    pet_id: int = Field(..., gt=0)
    metric_name: MetricName
    value: Union[float, int, str]
    notes: Optional[str] = Field(None, max_length=1000)

#ROUTES

class HealthMetricLogResponse(BaseModel):
    status: str
    analysis: str

@router.post("/log", response_model=HealthMetricLogResponse)
async def log_health_metric(
    log: HealthMetricLogCreate,
    db: Session = Depends(get_db)
):
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.metric_name == log.metric_name).first()
    
    if not metric_def:
        raise HTTPException(status_code=404, detail="Metric type not defined.")

    metric_val_to_save = 0
    notes_to_save = log.notes

    if metric_def.metric_unit == MetricUnit.text:
        metric_val_to_save = 0
        notes_to_save = str(log.value)
    else:
        try:
            metric_val_to_save = float(log.value)
        except ValueError:
            return {"status": "Error", "analysis": "ERROR: Quantitative metric received non-numeric value."}

    new_log = HealthMetric(
        pet_id=log.pet_id,
        metric_def_id=metric_def.metric_def_id,
        metric_value=metric_val_to_save,  # Must be metric_value
        metric_time=datetime.utcnow(), # Must be metric_time
        notes=notes_to_save
    )
    db.add(new_log)
    db.commit() 
    db.refresh(new_log)

    analysis = await analyze_health_metric(
        log.pet_id, 
        log.metric_name, 
        log.value, 
        metric_def.metric_unit, 
        db
    )
    
    return {"status": "Logged", "analysis": analysis}


async def analyze_health_metric(pet_id, metric_name, value, unit, db):
    
    if unit == MetricUnit.text:
        keywords = ["abnormal", "poor", "lethargic", "blood", "diarrhea"]
        if any(word in value.lower() for word in keywords):
            return "ALERT: Potential health issue detected based on notes."
        return "No concerning keywords detected in notes."
    
    # Fetch the previous record for baseline comparison
    previous = db.query(HealthMetric).join(MetricDefinition).filter(
            HealthMetric.pet_id == pet_id,
            MetricDefinition.metric_name == metric_name
    ).order_by(HealthMetric.metric_time.desc()).offset(1).first()

    if not previous:
        return "Baseline established."

    if unit in [MetricUnit.kg, MetricUnit.grams, MetricUnit.ml, MetricUnit.scale_1_5]:
        try:
            current_value = float(value)
            previous_value = float(previous.metric_value)

    
            if metric_name == MetricName.weight:
                if previous_value == 0:
                    return "Baseline was zero, increment detected."
                
                diff = abs(current_value - previous_value) / previous_value
                if diff >= 0.15:
                    return f"ALERT: Significant weight change ({round(diff * 100, 1)}%) detected."
                return "Weight stable."
            
            elif metric_name == MetricName.water_intake:
                diff = abs(current_value - previous_value)
                if diff >= 0.2:
                    return f"ALERT: Significant water intake change ({round(diff * 100, 1)}%) detected."
                return "Water intake stable."
            
            elif metric_name == MetricName.vomit_events:
                if current_value > previous_value:
                    return f"ALERT: Increase in vomit events from {previous_value} to {current_value}."
                return "Vomit events stable or decreased."
            
            elif metric_name == MetricName.energy_level:
                if current_value < previous_value:
                    return f"ALERT: Decrease in energy level from {previous_value} to {current_value}."
                return "Energy level stable or increased."
            
            elif metric_name == MetricName.appetite:
                if current_value < previous_value:
                    return f"ALERT: Decrease in appetite from {previous_value} to {current_value}."
                return "Appetite stable or increased."
            
            elif metric_name == MetricName.basking_time:
                if current_value < previous_value:
                    return f"ALERT: Decrease in basking time from {previous_value} to {current_value}."
                return "Basking time stable or increased."
            
            elif metric_name == MetricName.wheel_activity:
                if current_value < previous_value:
                    return f"ALERT: Decrease in wheel activity from {previous_value} to {current_value}."
                return "Wheel activity stable or increased."
            
            elif metric_name == MetricName.humidity_level:
                diff = abs(current_value - previous_value)
                if diff >= 10:
                    return f"ALERT: Significant humidity level change ({round(diff)}%) detected."
                return "Humidity level stable."
            
            return f"Change from last record: {round(current_value - previous_value, 2)} {unit.value}."
        except ValueError:
            return "ERROR: Quantitative metric received non-numeric value."
        
@router.get("/latest")
async def get_latest_metric(
    pet_id: int, 
    metric_name: MetricName, 
    db: Session = Depends(get_db)
):
    # Joins the metric definition and filters by pet and metric name
    record = db.query(HealthMetric).join(MetricDefinition).filter(
        HealthMetric.pet_id == pet_id,
        MetricDefinition.metric_name == metric_name
    ).order_by(HealthMetric.metric_time.desc()).first()
    
    if not record:
        return {"value": "---"}
    
    return {"value": record.metric_value}
        
        



   
