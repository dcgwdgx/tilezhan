"""订阅状态存储 — 内存 KV（生产环境应换成 Redis/DB）。

存两个映射：
- app_user_id → subscription tier + expiry
- 事件计数器（DAU / 购买 / 心耗尽 / 促销展示）
"""

from datetime import datetime
from typing import Optional
from collections import defaultdict

# ---- 订阅状态 ----
_subscriptions: dict[str, dict] = {}

# ---- 分析数据 ----
_daily: dict = {
    "dau": set(),
    "purchases": 0,
    "hearts_depleted": 0,
    "promo_shown": 0,
    "daily_challenge_used": 0,
}


def set_subscription(app_user_id: str, tier: str, expires_at: Optional[str] = None):
    _subscriptions[app_user_id] = {"tier": tier, "expires_at": expires_at}


def get_subscription(app_user_id: str) -> dict:
    return _subscriptions.get(app_user_id, {"tier": "free", "expires_at": None})


def remove_subscription(app_user_id: str):
    _subscriptions.pop(app_user_id, None)


# ---- 分析事件 ----
def track_event(event: str, user_id: str = ""):
    if event == "app_open":
        _daily["dau"].add(user_id)
    elif event == "purchase":
        _daily["purchases"] += 1
    elif event == "hearts_depleted":
        _daily["hearts_depleted"] += 1
    elif event == "promo_shown":
        _daily["promo_shown"] += 1
    elif event == "daily_challenge_used":
        _daily["daily_challenge_used"] += 1


def get_dashboard() -> dict:
    return {
        "dau": len(_daily["dau"]),
        "purchases": _daily["purchases"],
        "hearts_depleted": _daily["hearts_depleted"],
        "promo_shown": _daily["promo_shown"],
        "daily_challenge_used": _daily["daily_challenge_used"],
        "total_subscribers": sum(
            1 for s in _subscriptions.values() if s["tier"] != "free"
        ),
        "updated_at": datetime.now().isoformat(),
    }
