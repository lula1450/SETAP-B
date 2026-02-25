# 
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from database import get_db
from models import HealthMetric, MetricDefinition, MetricName, MetricUnit

router = APIRouter(
    prefix="/health",
    tags=["Health"]
)

@router.post("/log")
async def log_health_metric(
    pet_id: int, 
    metric_name: MetricName, 
    value: str, 
    notes: str = None, 
    db: Session = Depends(get_db)
):
    
    # find the metric definition for the given metric name
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.metric_name == metric_name).first()

    if not metric_def:
        raise HTTPException(status_code=404, detail="Metric type not defined.")
    
    # create new log entry
    new_log = HealthMetric(
        pet_id = pet_id,
        metric_def_id = metric_def.metric_def_id,
        metric_value = value,
        metric_time = datetime.utcnow(),
        notes = notes
    )   
    db.add(new_log)
    db.commit()

    analysis = await perform_weight_analysis(pet_id, metric_def.metric_name, new_log.metric_value, metric_def.metric_unit, db)

    return {"status": "Logged", "analysis": analysis}
    

    # QUANTITATIVE METRICS -- LOOK INTO CHANGING DEVIATION THRESHOLDS

    if unit in [MetricUnit.kg, MetricUnit.grams, MetricUnit.ml, MetricUnit.scale_1_5]:
        try:
            current_value = float(value)
            previous_value = float(previous.metric_value)

            if metric_name == MetricName.weight:
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
        
        


    # QUALITATIVE METRICS

    if unit == MetricUnit.text:
        keywords = ["abnormal", "poor", "lethargic", "blood", "diarrhea"]
        if any(word in value.lower() for word in keywords):
            return "ALERT: Potential health issue detected based on notes."
        return "No concerning keywords detected in notes."
    
    return "Logged successfully"