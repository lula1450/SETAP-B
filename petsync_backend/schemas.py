# data validation 

# basemodel = data contract, field = add constraints and desciptions 
from pydantic import BaseModel, Field 

# allows health log and reports to be chronologiaclly tracked for the dashboard
from datetime import datetime

# tells interpreter and API gateway that system. should not crash if user leaves a note blank
from typing import Optional, Union

# database session provider
from petsync_backend.database import get_db
from petsync_backend.models import MetricName

# imports for schedule router schemas
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

router = APIRouter(
    prefix="/health",
    tags=["Health"]
)


#SCHEMAS

#creates a schema for the health metric log endpoint to validate data before it reaches the database 
class HealthMetricLogCreate(BaseModel):
    pet_id: int = Field(..., gt=0, description="Foreign key link to the pet table")
    metric_name: MetricName
    value: Union[float, int, str]
    notes: Optional[str] = Field(None, max_length=1000)

# response model for the health metric log endpoint to structure the API response
class HealthMetricLogResponse(BaseModel):
    status: str
    analysis: str

# This file is for defining the data schemas used in the scheduling and reminders feature of the PetSync application.
@router.post("/log", response_model=HealthMetricLogResponse)
async def log_health_metric(
    payload: HealthMetricLogCreate,
    db: Session = Depends(get_db)
):
    return {"status": "Logged", "analysis": "Analysis pending implementation"}


class PetResponse(BaseModel):
    pet_id: int
    pet_first_name: str
    species_name: str | None = None
    owner_id: int | None = None

from pydantic import BaseModel

class PetCreate(BaseModel):
    species_id: int
    owner_id: int
    pet_first_name: str
    pet_last_name: str | None = None
    pet_address1: str | None = None
    pet_address2: str | None = None
    pet_city: str | None = None

class PetResponse(PetCreate):
    pet_id: int
    species_name: str | None = None


"""
# REPORTS 

# SR 3.1
class MetricLog(BaseModel): # validates health logs before passing them to the calculations engine

    # Field = required field ...
    pet_id: int = Field(..., description="Foreign key link to the pet table")
    metric_value: float = Field(..., description="Numerical health reading (DECIMAL in ERD)")
    
    # adds default time value - timestamp
    metric_time: Optional[datetime] = Field(default_factory=datetime.now)
    notes: Optional[str] = None # TEXT field in ERD - user can skip notes without causing error


class HealthReport(BaseModel):
    pet_id: int
    report_date: datetime = Field(default_factory=datetime.now)
    report_type: str = Field(..., description="ENUM type in ERD")
    risk_flag: bool = Field(..., description="BOOLEAN result from the 15% check") # SR 4.1
    notes: str = Field(..., description="Summary of the deviation findings")


    class Config:
        from_attributes = True # reduces the amount of manual data mapping required in report manager

"""