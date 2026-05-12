
from petsync_backend.routers import auth, pets, health, schedule, reports, owners
from petsync_backend.routers.owners import purge_owner, DELETION_GRACE_DAYS
from petsync_backend.middleware import PetSyncFirewall
from petsync_backend.database import SessionLocal
from petsync_backend import models

from fastapi import FastAPI, HTTPException, Request 
from fastapi.middleware.cors import CORSMiddleware # CORS middleware to allow cross-origin requests - important for frontend-backend communication
from fastapi.staticfiles import StaticFiles 

import os
import asyncio # for running the deletion purge loop in the background
from contextlib import asynccontextmanager # for managing the lifespan of the deletion purge loop
from datetime import datetime, timedelta
from pydantic import BaseModel 

import pandas as pd


def _run_deletion_purge() -> None: # owner deletion - permanent deletion after grace period
    db = SessionLocal()
    try:
        cutoff = datetime.utcnow() - timedelta(days=DELETION_GRACE_DAYS)
        expired = db.query(models.Owner).filter(
            models.Owner.deletion_requested_at != None,
            models.Owner.deletion_requested_at <= cutoff,
        ).all()
        for owner in expired:
            print(f"[purge] Permanently deleting owner_id={owner.owner_id} (requested {owner.deletion_requested_at})")
            purge_owner(owner, db)
    finally:
        db.close()


async def _deletion_purge_loop() -> None: # runs every hour to permanently delete owners whose deletion grace period has expired
    while True:
        await asyncio.get_running_loop().run_in_executor(None, _run_deletion_purge)
        await asyncio.sleep(3600)


@asynccontextmanager # FastAPI lifespan event to start the deletion purge loop when the app starts and stop it when the app shuts down
async def lifespan(app: FastAPI):
    task = asyncio.create_task(_deletion_purge_loop())
    yield
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title="PetSync API",
    version="1.0.0",
    lifespan=lifespan,
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

_seed_images_dir = os.path.join(os.path.dirname(__file__), "seed", "images")
app.mount("/static/seed_images", StaticFiles(directory=_seed_images_dir), name="seed_images")

@app.get("/")
async def root():
    return {"message": "PetSync API is running!"}


