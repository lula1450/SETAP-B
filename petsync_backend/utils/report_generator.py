"""
Automated Report Generation Utility
Generates weekly and monthly health reports for pets based on logged metrics.
"""

import json
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from petsync_backend.models import (
    Pet, PetReport, ReportFrequency, HealthMetric, MetricDefinition, MetricName
)
from petsync_backend.utils.calculations import check_15_percent_deviation


def generate_report_for_pet(
    db: Session, 
    pet_id: int, 
    frequency: ReportFrequency, 
    end_date: datetime = None
) -> PetReport:
    """
    Generate an automated report for a pet.
    
    Args:
        db: Database session
        pet_id: ID of the pet
        frequency: ReportFrequency (weekly or monthly)
        end_date: End date for the report period (defaults to now)
    
    Returns:
        PetReport instance
    """
    if end_date is None:
        end_date = datetime.utcnow()
    
    # Calculate start date based on frequency
    if frequency == ReportFrequency.weekly:
        start_date = end_date - timedelta(days=7)
    elif frequency == ReportFrequency.monthly:
        start_date = end_date - timedelta(days=30)
    else:
        raise ValueError(f"Unknown frequency: {frequency}")
    
    # Fetch pet to ensure it exists
    pet = db.query(Pet).filter(Pet.pet_id == pet_id).first()
    if not pet:
        raise ValueError(f"Pet ID {pet_id} not found")
    
    # Fetch all metrics for this pet in the time range
    metrics_data = db.query(HealthMetric).filter(
        HealthMetric.pet_id == pet_id,
        HealthMetric.metric_time >= start_date,
        HealthMetric.metric_time <= end_date
    ).order_by(HealthMetric.metric_time.asc()).all()
    
    # Group metrics by metric definition
    metrics_by_def = {}
    for metric in metrics_data:
        def_id = metric.metric_def_id
        if def_id not in metrics_by_def:
            metrics_by_def[def_id] = []
        metrics_by_def[def_id].append(metric)
    
    # Analyze each metric
    report_summary = {
        "metrics": {},
        "risk_flags": [],
        "generated_at": end_date.isoformat()
    }
    
    has_risk_flags = False
    
    for def_id, metric_logs in metrics_by_def.items():
        metric_def = db.query(MetricDefinition).filter(
            MetricDefinition.metric_def_id == def_id
        ).first()
        
        if not metric_def:
            continue
        
        metric_name = metric_def.metric_name.value
        values = [float(log.metric_value) for log in metric_logs]
        
        if len(values) < 2:
            # Not enough data for analysis
            report_summary["metrics"][metric_name] = {
                "count": len(values),
                "latest": values[-1] if values else None,
                "status": "insufficient_data"
            }
            continue
        
        current_value = values[-1]
        historical_values = values[:-1]
        
        # Check for 15% deviation
        is_risk, baseline = check_15_percent_deviation(historical_values, current_value)
        
        report_summary["metrics"][metric_name] = {
            "count": len(values),
            "latest": current_value,
            "baseline": baseline,
            "status": "at_risk" if is_risk else "stable",
            "min": min(values),
            "max": max(values),
            "average": sum(values) / len(values)
        }
        
        if is_risk:
            has_risk_flags = True
            report_summary["risk_flags"].append({
                "metric": metric_name,
                "current": current_value,
                "baseline": baseline,
                "deviation_percent": abs((current_value - baseline) / baseline * 100) if baseline != 0 else 0
            })
    
    # Create the report
    pet_report = PetReport(
        pet_id=pet_id,
        report_frequency=frequency,
        report_date=end_date,
        start_date=start_date,
        end_date=end_date,
        report_summary=json.dumps(report_summary),
        has_risk_flags=has_risk_flags
    )
    
    db.add(pet_report)
    db.commit()
    db.refresh(pet_report)
    
    return pet_report


def generate_reports_for_all_pets(db: Session, frequency: ReportFrequency):
    """
    Generate reports for all pets for a given frequency.
    Called by the scheduler.
    
    Args:
        db: Database session
        frequency: ReportFrequency (weekly or monthly)
    """
    pets = db.query(Pet).all()
    reports_created = 0
    
    for pet in pets:
        try:
            generate_report_for_pet(db, pet.pet_id, frequency)
            reports_created += 1
        except Exception as e:
            print(f"Error generating report for pet {pet.pet_id}: {str(e)}")
    
    print(f"✅ Generated {reports_created} {frequency.value} reports")
    return reports_created


def get_report_history(db: Session, pet_id: int, limit: int = 50) -> list:
    """
    Retrieve report history for a pet.
    
    Args:
        db: Database session
        pet_id: ID of the pet
        limit: Maximum number of reports to retrieve
    
    Returns:
        List of PetReport instances
    """
    return db.query(PetReport).filter(
        PetReport.pet_id == pet_id
    ).order_by(PetReport.report_date.desc()).limit(limit).all()
