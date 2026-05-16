from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse

from sqlalchemy.orm import Session

from petsync_backend.database import get_db
from petsync_backend.models import HealthMetric, MetricDefinition, Pet, MetricName, PetReport
from petsync_backend.utils.calculations import check_15_percent_deviation
from petsync_backend.utils.pdf_generator import generate_health_pdf
from petsync_backend.utils.report_generator import get_report_history
from petsync_backend.schemas import PetReportResponse

from datetime import datetime

from typing import Optional, List

router = APIRouter(tags=["Reporting Engine"])

@router.get("/analysis/{pet_id}/{metric_name}")
async def get_metric_analysis(
    pet_id: int,
    metric_name: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    Analyses all logged entries for a specific metric and returns trend data for the chart.

    Checks whether the latest value deviates more than 15% from the historical mean (SR 4.1).
    Returns data points formatted for fl_chart: x = index, y = value, date = formatted string.
    Optional start_date/end_date parameters (ISO format) narrow the analysis window.
    """
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail=f"Pet ID {pet_id} not found in DB")

    # Normalise to snake_case to match MetricDefinition values (e.g. 'Water Intake' -> 'water_intake')
    formatted_name = metric_name.lower().replace(" ", "_")

    metric_def = db.query(MetricDefinition).filter(
        MetricDefinition.species_id == pet.species_id,
        MetricDefinition.metric_name == formatted_name
    ).first()

    if not metric_def:
        raise HTTPException(status_code=404, detail=f"Metric '{formatted_name}' not defined for this species")

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

    logs = query.order_by(HealthMetric.metric_time.asc()).all()

    if not logs:
        return {"message": "No logs recorded yet", "points": [], "is_risk": False}

    values = [float(log.metric_value) for log in logs]
    current_value = values[-1]
    historical_values = values[:-1]

    is_risk, baseline = check_15_percent_deviation(historical_values, current_value)

    # Format points for fl_chart: x is the index, date formatted as "28 Mar, 19:40"
    graph_points = []
    for i, log in enumerate(logs):
        graph_points.append({
            "x": i,
            "y": float(log.metric_value),
            "date": log.metric_time.strftime("%d %b, %H:%M")
        })

    return {
        "metric": metric_name,
        "is_risk": bool(is_risk),
        "baseline": float(baseline),
        "current": float(current_value),
        "message": "⚠️ Significant change detected!" if is_risk else "✅ Health stable",
        "points": graph_points
    }

@router.get("/export-pdf/{pet_id}/{metric_name}")
async def export_pet_report(pet_id: int, metric_name: str, db: Session = Depends(get_db)):
    """Generates and streams a PDF health report for the specified metric as a file download."""
    analysis = await get_metric_analysis(pet_id, metric_name, db)
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()

    pdf_buffer = generate_health_pdf(pet.pet_first_name, metric_name, analysis)

    return StreamingResponse(
        pdf_buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={pet.pet_first_name}_report.pdf"}
    )

@router.get("/logged-metrics/{pet_id}")
async def get_logged_metrics(pet_id: int, db: Session = Depends(get_db)):
    """Returns the distinct metric names that have at least one logged entry for this pet."""
    # Returns unique metric names that have at least one log entry for this pet
    logged_metrics = db.query(MetricDefinition.metric_name)\
        .join(HealthMetric, HealthMetric.metric_def_id == MetricDefinition.metric_def_id)\
        .filter(HealthMetric.pet_id == pet_id)\
        .distinct().all()

    return [m[0] for m in logged_metrics]

@router.get("/history/{pet_id}", response_model=List[PetReportResponse])
async def get_pet_report_history(pet_id: int, db: Session = Depends(get_db)):
    """Retrieve all generated reports for a pet."""
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise HTTPException(status_code=404, detail=f"Pet ID {pet_id} not found")

    reports = get_report_history(db, pet_id)
    return reports

@router.get("/detail/{report_id}", response_model=PetReportResponse)
async def get_report_detail(report_id: int, db: Session = Depends(get_db)):
    """Retrieve details of a specific report."""
    report = db.query(PetReport).filter(PetReport.pet_report_id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail=f"Report ID {report_id} not found")

    return report
