"""User API — Profile, Progress, Stamina with NTP anti-cheat."""

from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_current_user
from app.core.ntp_guard import validate_client_timestamp
from datetime import datetime, timezone

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
    return {
        "hearts": 3,
        "max_hearts": 3,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }


@router.post("/stamina/consume")
async def consume_stamina(
    payload: dict,
    user: dict = Depends(get_current_user),
):
    """Consume 1 heart. Requires client_timestamp for NTP validation."""
    client_timestamp = payload.get("client_timestamp", 0)
    validate_client_timestamp(client_timestamp)

    hearts = payload.get("hearts_before", 3)
    if hearts <= 0:
        raise HTTPException(status_code=400, detail="No hearts remaining")

    return {
        "hearts": hearts - 1,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }
