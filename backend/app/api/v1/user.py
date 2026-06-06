"""User API — Profile, Progress, Stamina"""

from fastapi import APIRouter, Depends
from app.api.deps import get_current_user

router = APIRouter(prefix="/user", tags=["User"])


@router.get("/profile")
async def get_profile(user: dict = Depends(get_current_user)):
    return {
        "uid": user["uid"],
        "display_name": "Tile Master",
        "stats": {"elo_rating": 1200, "current_streak": 0},
        "stamina": {"hearts": 3, "max_hearts": 3},
        "subscription_tier": "free",
    }


@router.get("/stamina")
async def get_stamina(user: dict = Depends(get_current_user)):
    from datetime import datetime, timezone
    return {
        "hearts": 3,
        "max_hearts": 3,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }
