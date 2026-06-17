"""
订阅 API — RevenueCat Webhook 接收 + 状态验证 + 权限查询。

本模块处理与 RevenueCat 订阅系统的全部交互：

端点一览：
- POST /subscription/verify：验证当前用户的订阅是否有效
- GET /subscription/status：查询当前用户的订阅等级和过期时间
- POST /subscription/webhooks/revenuecat：接收 RevenueCat 服务器通知

RevenueCat Webhook 事件类型：
- INITIAL_PURCHASE   → 新订阅开通 → 写入 premium/lifetime 状态
- RENEWAL            → 自动续期成功 → 更新过期时间
- CANCELLATION       → 用户取消订阅（到期前仍有效，到期后变 EXPIRATION）
- EXPIRATION         → 订阅已过期 → 移除订阅状态，降级为 free
- NON_RENEWING_PURCHASE → 买断型商品（如 Lifetime）→ 写入 lifetime 状态

Webhook 安全：
    通过验证 Authorization 头中的 Bearer token 与
    REVENUECAT_WEBHOOK_SECRET 配置项匹配，防止伪造调用。
    未配置 secret 时跳过验证（仅限开发环境）。
"""

from fastapi import APIRouter, Depends, Request
from app.api.deps import get_current_user
from app.core.subscription_store import (
    get_subscription, set_subscription, remove_subscription, track_event
)

router = APIRouter(prefix="/subscription", tags=["Subscription"])


@router.post("/verify")
async def verify_subscription(user: dict = Depends(get_current_user)):
    """
    验证当前用户的订阅状态。

    由客户端在 App 启动或恢复前台时调用，
    用于确定是否应展示付费墙或解锁 Pro 功能。

    Args:
        user: 当前用户信息。

    Returns:
        dict: 包含 is_pro（布尔）、tier（等级字符串）、expires_at（过期时间）。
    """
    uid = user.get("uid", "")
    sub = get_subscription(uid)
    return {
        "is_pro": sub["tier"] != "free",
        "tier": sub["tier"],
        "expires_at": sub.get("expires_at"),
    }


@router.get("/status")
async def get_status(user: dict = Depends(get_current_user)):
    """
    查询当前用户的订阅等级和过期时间。

    轻量端点，仅返回订阅核心信息，不包含 is_pro 计算。

    Args:
        user: 当前用户信息。

    Returns:
        dict: 包含 tier 和 expires_at 字段。
    """
    uid = user.get("uid", "")
    sub = get_subscription(uid)
    return {"tier": sub["tier"], "expires_at": sub.get("expires_at")}


@router.post("/webhooks/revenuecat")
async def revenuecat_webhook(request: Request):
    """
    RevenueCat 服务器到服务器 (S2S) 通知接收端点。

    此端点由 RevenueCat 后台在订阅事件发生时自动调用，
    不应由客户端直接访问。

    安全机制：
    - 验证 Authorization: Bearer <secret> 头
    - 与 settings.REVENUECAT_WEBHOOK_SECRET 严格比对
    - 若未配置 secret（开发环境），跳过验证

    事件处理逻辑：
    - INITIAL_PURCHASE / RENEWAL → 写入订阅状态 + 记录购买事件
    - CANCELLATION / EXPIRATION → 移除订阅状态
    - NON_RENEWING_PURCHASE → 写入 lifetime 状态 + 记录购买事件

    Args:
        request: 原始 FastAPI Request 对象，包含 RevenueCat 发送的 JSON body。

    Returns:
        dict: {"status": "ok"|"unauthorized"|"invalid_body", ...}
    """
    # ==== Webhook 签名验证 ====
    expected = settings.REVENUECAT_WEBHOOK_SECRET
    if expected:
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer ") or auth[7:] != expected:
            return {"status": "unauthorized", "detail": "Invalid webhook secret"}

    # ==== 解析请求体 ====
    try:
        body = await request.json()
    except Exception:
        return {"status": "invalid_body"}

    # ==== 提取事件信息 ====
    event = body.get("event", {})
    event_type = event.get("type", "")
    event_data = event.get("data", {})
    app_user_id = event.get("app_user_id", "")
    product_id = event_data.get("product_id", "")
    expires_at = event_data.get("expiration_at_ms")

    # ==== 按事件类型更新订阅状态 ====
    if event_type in ("INITIAL_PURCHASE", "RENEWAL"):
        # 判断是否为 Lifetime 买断（产品 ID 含 "lifetime" 关键字）
        tier = "lifetime" if "lifetime" in product_id else "premium"
        set_subscription(app_user_id, tier, expires_at)
        track_event("purchase", app_user_id)
    elif event_type in ("CANCELLATION", "EXPIRATION"):
        # 取消或过期 → 移除订阅记录，用户降级为 free
        remove_subscription(app_user_id)
    elif event_type == "NON_RENEWING_PURCHASE":
        # 买断型商品（不自动续期）
        set_subscription(app_user_id, "lifetime", None)
        track_event("purchase", app_user_id)

    return {"status": "ok", "event_type": event_type}
