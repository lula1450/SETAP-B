from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, Union, List
from petsync_backend.models import MetricName

# --- 1. OWNER SCHEMAS ---
class OwnerBase(BaseModel):
    owner_first_name: str
    owner_last_name: str
    owner_email: str
    owner_phone_number: str
    owner_address1: str
    owner_address2: Optional[str] = None
    owner_postcode: str
    owner_city: str

class OwnerCreate(OwnerBase):
    password: str # Added this so registration works!

class OwnerResponse(OwnerBase):
    owner_id: int
    model_config = ConfigDict(from_attributes=True)

# --- 2. PET SCHEMAS ---
class PetBase(BaseModel):
    species_id: int 
    owner_id: int 
    pet_first_name: str = Field(..., min_length=1, max_length=50)
    # FIXED: Optional last name with empty string default for UI compatibility
    pet_last_name: Optional[str] = "" 
    pet_address1: Optional[str] = None
    pet_address2: Optional[str] = None
    pet_postcode: Optional[str] = None
    pet_city: Optional[str] = None

class PetCreate(PetBase):
    pass

class PetResponse(PetBase):
    pet_id: int
    # species_name is helpful for the Flutter dashboard
    species_name: Optional[str] = "Unknown" 
    
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