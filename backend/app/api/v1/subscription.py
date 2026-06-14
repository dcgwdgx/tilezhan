"""订阅 API — RevenueCat webhook + 验证 + 状态查询。

RevenueCat webhook 事件类型：
- INITIAL_PURCHASE → 新订阅
- RENEWAL → 续期
- CANCELLATION → 取消（到期后失效）
- EXPIRATION → 过期
- NON_RENEWING_PURCHASE → 买断（Lifetime）
"""

from fastapi import APIRouter, Depends, Request
from app.api.deps import get_current_user
from app.core.subscription_store import (
    get_subscription, set_subscription, remove_subscription, track_event
)

router = APIRouter(prefix="/subscription", tags=["Subscription"])


@router.post("/verify")
async def verify_subscription(user: dict = Depends(get_current_user)):
    """验证当前用户的订阅状态。"""
    uid = user.get("uid", "")
    sub = get_subscription(uid)
    return {"is_pro": sub["tier"] != "free", "tier": sub["tier"], "expires_at": sub.get("expires_at")}


@router.get("/status")
async def get_status(user: dict = Depends(get_current_user)):
    """查询当前用户的订阅等级和过期时间。"""
    uid = user.get("uid", "")
    sub = get_subscription(uid)
    return {"tier": sub["tier"], "expires_at": sub.get("expires_at")}


@router.post("/webhooks/revenuecat")
async def revenuecat_webhook(request: Request):
    """RevenueCat 服务器到服务器通知。

    生产环境应验证 Authorization 头中的 webhook secret。
    当前信任 RevenueCat 来源（测试阶段），后续加固时添加签名验证。
    """
    try:
        body = await request.json()
    except Exception:
        return {"status": "invalid_body"}

    event = body.get("event", {})
    event_type = event.get("type", "")
    event_data = event.get("data", {})
    app_user_id = event.get("app_user_id", "")
    product_id = event_data.get("product_id", "")
    expires_at = event_data.get("expiration_at_ms")

    if event_type in ("INITIAL_PURCHASE", "RENEWAL"):
        tier = "lifetime" if "lifetime" in product_id else "premium"
        set_subscription(app_user_id, tier, expires_at)
        track_event("purchase", app_user_id)
    elif event_type in ("CANCELLATION", "EXPIRATION"):
        remove_subscription(app_user_id)
    elif event_type == "NON_RENEWING_PURCHASE":
        set_subscription(app_user_id, "lifetime", None)
        track_event("purchase", app_user_id)

    return {"status": "ok", "event_type": event_type}
