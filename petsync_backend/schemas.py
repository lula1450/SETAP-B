# data validation 

# basemodel = data contract, field = add constraints and desciptions 
from pydantic import BaseModel, Field 

# allows health log and reports to be chronologiaclly tracked for the dashboard
from datetime import datetime

# tells interpreter and API gateway that system. should not crash if user leaves a note blank
from typing import Optional


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
