"""SRS (Spaced Repetition System) API"""

from fastapi import APIRouter, Depends
from app.api.deps import get_current_user

router = APIRouter(prefix="/srs", tags=["SRS"])


@router.get("/review_due")
async def get_due_reviews(user: dict = Depends(get_current_user)):
    return {"items": [], "count": 0}


@router.post("/report")
async def report_answer(report: dict, user: dict = Depends(get_current_user)):
    quality = report.get("quality", 3)
    if quality < 3:
        ef, interval, reps = 2.5, 1, 0
    else:
        ef = max(1.3, 2.5 + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        reps = 1
        interval = 1 if reps == 1 else 6
    return {
        "tile_id": report.get("tile_id"),
        "easiness_factor": ef,
        "interval_days": interval,
        "repetitions": reps,
    }
