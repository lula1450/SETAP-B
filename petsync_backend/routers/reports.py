# petsync_backend/routers/reports.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from petsync_backend.database import get_db
from petsync_backend.models import HealthMetric, MetricDefinition, Pet, MetricName
from petsync_backend.calculations import check_15_percent_deviation
from fastapi.responses import StreamingResponse
from petsync_backend.utils.pdf_generator import generate_health_pdf
from datetime import datetime
from typing import Optional

router = APIRouter(tags=["Reporting Engine"])

@router.get("/analysis/{pet_id}/{metric_name}")
async def get_metric_analysis(
    pet_id: int,
    metric_name: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
):
    # 1. Verify Pet and Metric Definition
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        # This will tell us if the Pet simply doesn't exist in the API's view
        raise HTTPException(status_code=404, detail=f"Pet ID {pet_id} not found in DB")

    # Standardize the incoming string (e.g. 'Water Intake' -> 'water_intake')
    # Standardize the incoming string (e.g. 'Weight' -> 'weight')
    formatted_name = metric_name.lower().replace(" ", "_")
    
    # FIX: Use the string value of the enum for the filter
    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == formatted_name  # SQLAlchemy handles the Enum cast automatically here
    ).first()

    if not metric_def:
        # Change this to a 404 so the test knows why it failed
        raise HTTPException(status_code=404, detail=f"Metric '{formatted_name}' not defined for this species")

    # 2. Fetch logs for this metric, optionally filtered by date range
    query = db.query(HealthMetric).filter(
        HealthMetric.pet_id == pet_id,
        HealthMetric.metric_def_id == metric_def.metric_def_id
    )
    
    # Apply optional date filters (expecting ISO format strings)
    if start_date:
        try:
            start_dt = datetime.fromisoformat(start_date)
        except ValueError:
            raise HTTPException(status_code=400, detail="start_date must be ISO format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)")
        query = query.filter(HealthMetric.metric_time >= start_dt)
    if end_date:
        try:
            end_dt = datetime.fromisoformat(end_date)
        except ValueError:
            raise HTTPException(status_code=400, detail="end_date must be ISO format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)")
        query = query.filter(HealthMetric.metric_time <= end_dt)

    # This ensures the graph line moves forward in time.
    logs = query.order_by(HealthMetric.metric_time.asc()).all()
     
    if not logs:
        return {"message": "No logs recorded yet", "points": [], "is_risk": False}

    # 3. Process data for the Pandas Engine
    values = [float(log.metric_value) for log in logs]
    current_value = values[-1]
    historical_values = values[:-1] # All entries except the latest one

    # 4. Perform the 15% deviation check
    is_risk, baseline = check_15_percent_deviation(historical_values, current_value)

    # 5. Format the data points specifically for Flutter's fl_chart (X and Y)
    graph_points = []
    for i, log in enumerate(logs):
        # Ensure each point has a 'date' key in the requested format e.g. "28 Mar, 19:40"
        graph_points.append({
            "x": i,
            "y": float(log.metric_value),
            "date": log.metric_time.strftime("%d %b, %H:%M")
        })

    return {
        "metric": metric_name,
        "is_risk": bool(is_risk),    # ensure standard Python bool
        "baseline": float(baseline), # ensure standard Python float
        "current": float(current_value),
        "message": "⚠️ Significant change detected!" if is_risk else "✅ Health stable",
        "points": graph_points
    }

@router.get("/export-pdf/{pet_id}/{metric_name}")
async def export_pet_report(pet_id: int, metric_name: str, db: Session = Depends(get_db)):
    # 1. Reuse existing analysis logic to get the data
    analysis = await get_metric_analysis(pet_id, metric_name, db)
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()

    # 2. Generate the PDF buffer (expects BytesIO or file-like)
    pdf_buffer = generate_health_pdf(pet.pet_first_name, metric_name, analysis)

    # 3. Return as a downloadable file
    return StreamingResponse(
        pdf_buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={pet.pet_first_name}_report.pdf"}
    )