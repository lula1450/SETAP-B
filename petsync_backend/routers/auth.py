from fastapi import APIRouter
from petsync_backend import models, schemas
from petsync_backend.database import get_db

# This allows main.py to "include" this section of the API
router = APIRouter()

@router.get("/")
async def status():
    return {"message": "Feature pending implementation"}