"""分析 API — 仪表盘数据 + 事件追踪。"""

from fastapi import APIRouter, Request
from app.core.subscription_store import track_event, get_dashboard

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/dashboard")
async def dashboard():
    """返回管理面板所需的关键指标。"""
    return get_dashboard()


@router.post("/track")
async def track(request: Request):
    """前端上报事件：app_open / hearts_depleted / promo_shown / daily_challenge_used。"""
    try:
        body = await request.json()
    except Exception:
        return {"status": "invalid_body"}
    event = body.get("event", "")
    user_id = body.get("user_id", "")
    track_event(event, user_id)
    return {"status": "ok"}
