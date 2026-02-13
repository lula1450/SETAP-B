# apirouter = allows you to split API into logical sections = easy to folllow
# http = return standard error codes to user
# depends = when connection starts
from fastapi import APIRouter, HTTPException, Depends

from sqlalchemy.orm import Session # session = ensures connection is open

from datetime import datetime # allows timestamp

from schemas import MetricLog, HealthReport # ensures report data follows the rules set in the schema

from calculations import check_15_percent_deviation # imports the math/ logic

from database import get_db, HealthMetric # bridge database


router = APIRouter(prefix="/reports", tags=["Reports Manager"])

# sends data to the server for processing
@router.post("/analyze", response_model=HealthReport) # ensures API only sends back specific details = protect sensitive data
async def analyse_health_metric(log: MetricLog, db: Session = Depends(get_db)): # automatically validates using schema and gets live db

# query last 10 entries for specific pet to establish a baseline
    db_history = db.query(HealthMetric).filter(
        HealthMetric.pet_id == log.pet_id
    ).order_by(HealthMetric.metric_time.desc()).limit(10).all()

# ccnvert db object to list for engine
    historical_values = [h.metric_value for h in db_history]


# trigger logic engine from calculations
# passes historical data and new value and receives back a boolean and baseline
    is_risk, baseline = check_15_percent_deviation(historical_values, log.metric_value)


    report = HealthReport(
        pet_id=log.pet_id, # links repors to correct pet
        report_date=datetime.now(),
        report_type="health_alert",
        risk_flag=is_risk, # stores result of safety check
        notes=f"Baseline established at {baseline:.2f}. Input value: {log.metric_value}."
    )

    return report