"""
分析 API — 运营仪表盘数据 + 前端事件追踪。

提供管理员和运营所需的两个核心端点：
- GET /analytics/dashboard：返回关键业务指标面板
- POST /analytics/track：接收前端上报的客户端事件

事件追踪覆盖核心转化漏斗：
    App 打开 (DAU) → 心耗尽 → 促销展示 → 购买 → 每日挑战完成

数据存储：
    使用 subscription_store 模块的内存存储，
    生产环境应迁移至独立的分析数据库（如 BigQuery）。

注意：
    此模块的 endpoint 没有用户认证（dashboard 用于管理面板，
    track 由前端匿名上报），生产环境需要添加适当的权限控制。
"""

from fastapi import APIRouter, Request
from app.core.subscription_store import track_event, get_dashboard

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/dashboard")
async def dashboard():
    """
    返回运营管理面板所需的关键指标。

    数据内容（详见 get_dashboard 文档）：
    - 今日核心指标（DAU、心耗尽、促销展示、购买、挑战使用）
    - 转化漏斗各步转化率
    - 估算收入
    - 最近 7 天历史快照

    Returns:
        dict: 结构化仪表盘数据。
    """
    return get_dashboard()


@router.post("/track")
async def track(request: Request):
    """
    接收前端上报的客户端行为事件。

    支持的事件类型（由 event 字段指定）：
    - "app_open": 应用打开 → DAU 计数
    - "hearts_depleted": 心耗尽 → 触发促销场景计数
    - "promo_shown": 促销展示 → 付费墙展示计数
    - "daily_challenge_used": 每日挑战完成
    - "purchase": 购买事件（通常由 webhook 触发，前端也可上报）

    Args:
        request: 原始请求对象，JSON body 需包含：
            - event (str): 事件类型。
            - user_id (str): 触发事件的用户标识符。

    Returns:
        dict: {"status": "ok"} 或 {"status": "invalid_body"}。
    """
    try:
        body = await request.json()
    except Exception:
        return {"status": "invalid_body"}

    event = body.get("event", "")
    user_id = body.get("user_id", "")
    track_event(event, user_id)
    return {"status": "ok"}
