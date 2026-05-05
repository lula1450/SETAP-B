from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, Union, List
from petsync_backend.models import MetricName

# --- 1. OWNER SCHEMAS ---
class OwnerBase(BaseModel):
    owner_first_name: str
    owner_last_name: str
    owner_email: str

class OwnerCreate(OwnerBase):
    password: str

class OwnerUpdate(BaseModel):
    owner_first_name: Optional[str] = None
    owner_last_name: Optional[str] = None
    owner_email: Optional[str] = None
    password: Optional[str] = None

class OwnerResponse(OwnerBase):
    owner_id: int
    password: str
    model_config = ConfigDict(from_attributes=True)

# --- 2. PET SCHEMAS ---
class PetBase(BaseModel):
    species_id: int
    owner_id: int
    pet_first_name: str = Field(..., min_length=1, max_length=50)
    pet_last_name: Optional[str] = ""

class PetCreate(PetBase):
    pass

class PetResponse(PetBase):
    pet_id: int
    species_name: Optional[str] = "Unknown"
    pet_image_path: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

# --- 3. HEALTH & METRIC SCHEMAS ---
class HealthMetricLogCreate(BaseModel):
    pet_id: int = Field(..., gt=0)
    metric_name: MetricName
    value: Union[float, int, str]
    notes: Optional[str] = Field(None, max_length=1000)

class HealthMetricLogResponse(BaseModel):
    status: str
    analysis: str

# Added this to support the Goal column in Flutter
class MetricGoalUpdate(BaseModel):
    pet_id: int
    metric_name: str
    goal: str

# --- 4. REPORT SCHEMAS ---
class MetricLog(BaseModel): 
    pet_id: int
    metric_value: float
    metric_time: Optional[datetime] = Field(default_factory=datetime.now)
    notes: Optional[str] = None

class HealthReport(BaseModel):
    pet_id: int
    report_date: datetime = Field(default_factory=datetime.now)
    report_type: str
    risk_flag: bool
    notes: str

    model_config = ConfigDict(from_attributes=True)

class PetReportResponse(BaseModel):
    pet_report_id: int
    pet_id: int
    report_frequency: str
    report_date: datetime
    start_date: datetime
    end_date: datetime
    report_summary: str  # JSON string
    has_risk_flags: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)