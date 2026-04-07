
from petsync_backend.routers import auth, pets, health, schedule, reports, owners
from petsync_backend.middleware import PetSyncFirewall

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
from datetime import datetime


app = FastAPI(
    title="PetSync API",
    version="1.0.0"
)

app.add_middleware(PetSyncFirewall)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(pets.router, prefix="/pets", tags=["pets"])
app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(schedule.router, prefix="/schedule", tags=["schedule"])
app.include_router(reports.router, prefix="/reports", tags=["reports"])
app.include_router(owners.router, prefix="/owners", tags=["owners"])

@app.get("/")
async def root():
    return {"message": "PetSync API is running!"}


