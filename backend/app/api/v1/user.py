"""
用户 API — 个人资料、体力系统与 NTP 防作弊。

提供用户相关的核心端点：
- GET /user/profile：获取用户完整资料
- GET /user/stamina：查询体力和服务端时间
- POST /user/stamina/consume：消耗体力（含时间戳防作弊校验）

体力系统设计：
- 每用户初始 3 颗心（hearts）
- 每次 consume 消耗 1 颗心
- hearts <= 0 时返回 400 错误
- 通过 NTP 时间戳验证防止修改手机时钟绕过冷却
"""

from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_current_user
from app.core.ntp_guard import validate_client_timestamp
from datetime import datetime, timezone

router = APIRouter(prefix="/user", tags=["User"])


@router.get("/profile")
async def get_profile(user: dict = Depends(get_current_user)):
    """
    获取当前用户的完整个人资料。

    返回信息包括：
    - uid: 用户唯一标识
    - display_name: 显示名称
    - stats: 游戏统计（ELO 评分、连胜天数）
    - stamina: 体力状态（当前心数、最大心数）
    - subscription_tier: 订阅等级

    Args:
        user: 当前用户信息。

    Returns:
        dict: 用户资料（当前为模板数据，生产环境应从数据库读取）。
    """
    return {
        "uid": user["uid"],
        "display_name": "Tile Master",
        "stats": {"elo_rating": 1200, "current_streak": 0},
        "stamina": {"hearts": 3, "max_hearts": 3},
        "subscription_tier": "free",
    }


@router.get("/stamina")
async def get_stamina(user: dict = Depends(get_current_user)):
    """
    查询当前用户的体力状态。

    同时返回服务端 UTC 时间，供客户端校准本地时钟。

    Args:
        user: 当前用户信息。

    Returns:
        dict: 包含 hearts、max_hearts 和 server_time（ISO 格式）。
    """
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
    """
    消耗 1 颗体力心。

    安全机制：
    1. client_timestamp 校验：调用 validate_client_timestamp()
       检测客户端时间是否与服务端偏差超过 5 分钟，
       防止通过修改手机时钟绕过体力冷却。
    2. 体力检查：若 hearts_before <= 0，拒绝消耗。

    Args:
        payload: 请求体，需包含：
            - client_timestamp (int): 客户端毫秒级 Unix 时间戳。
            - hearts_before (int): 消耗前的体力心数。
        user: 当前用户信息。

    Returns:
        dict: 包含更新后的 hearts 和 server_time。

    Raises:
        HTTPException 400: 体力不足。
        TimestampTampered: 客户端时间偏差过大。
    """
    # NTP 时间防作弊校验
    client_timestamp = payload.get("client_timestamp", 0)
    validate_client_timestamp(client_timestamp)

    hearts = payload.get("hearts_before", 3)
    if hearts <= 0:
        raise HTTPException(status_code=400, detail="No hearts remaining")

    return {
        "hearts": hearts - 1,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }
