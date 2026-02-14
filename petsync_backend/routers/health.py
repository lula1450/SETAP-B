from fastapi import APIRouter

# This allows main.py to "include" this section of the API
router = APIRouter()

@router.get("/")
async def status():
    return {"message": "Feature pending implementation"}