
# allows the api gateway to handle concurrent requests
from fastapi import FastAPI, HTTPException

# ensures that the data entering the user manager or pet manger is typed and validated
from pydantic import BaseModel


# process historical health data stored in the database
# make comparisons between data entries
import pandas as pd

# validatae that appointments are not set in the past - allows timestamps - chronological order
from datetime import datetime

from routers import auth, pets, health, schedule, reports

# create the FastAPI app instance

# pip install - uvicorn - environment to host api - ensures the application layer remains stable

# background dependency
# pip install - python-multipart - allows FastAPI to handle form data and file uploads - HRM from AUTH UI to OSS


app = FastAPI(
    title="PetSync API",
    version="1.0.0"
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(pets.router, prefix="/pets", tags=["pets"])
app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(schedule.router, prefix="/schedule", tags=["schedule"])
app.include_router(reports.router, prefix="/reports", tags=["reports"])

@app.get("/")
async def root():
    return {"message": "PetSync API is running!"}


