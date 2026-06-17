"""订阅状态存储 + 分析数据 — 内存 KV + 时间序列。

结构：
- _subscriptions: app_user_id → {tier, expires_at}
- _daily: 今日实时计数器
- _history: 每日零点快照 [DAU，购买，心耗尽，促销，挑战，付费用户数]
- _revenue: 估算收入累计 ($)
"""

from datetime import datetime, date
from typing import Optional
from collections import defaultdict

# ---- 订阅状态 ----
_subscriptions: dict[str, dict] = {}

# ---- 今日实时数据 ----
_daily: dict = {
    "dau": set(),
    "purchases": 0,
    "hearts_depleted": 0,
    "promo_shown": 0,
    "daily_challenge_used": 0,
}
_last_snapshot_date: str = ""  # ISO date string

# ---- 历史每日快照 ----
_history: list[dict] = []  # newest first

# ---- 估算收入 ----
_revenue: float = 0.0  # cumulative


def _maybe_snapshot():
    """日期变更时将今日数据存入 _history 并清零计数器。"""
    global _last_snapshot_date
    today = date.today().isoformat()
    if _last_snapshot_date and _last_snapshot_date == today:
        return
    if _last_snapshot_date:  # end of previous day — snapshot before reset
        _history.insert(0, {
            "date": _last_snapshot_date,
            "dau": len(_daily["dau"]),
            "purchases": _daily["purchases"],
            "hearts_depleted": _daily["hearts_depleted"],
            "promo_shown": _daily["promo_shown"],
            "daily_challenge_used": _daily["daily_challenge_used"],
            "subscribers": sum(1 for s in _subscriptions.values() if s["tier"] != "free"),
            "revenue": _revenue,
        })
    _last_snapshot_date = today
    _daily["dau"] = set()
    _daily["purchases"] = 0
    _daily["hearts_depleted"] = 0
    _daily["promo_shown"] = 0
    _daily["daily_challenge_used"] = 0


# ---- 订阅操作 ----
def set_subscription(app_user_id: str, tier: str, expires_at: Optional[str] = None):
    _subscriptions[app_user_id] = {"tier": tier, "expires_at": expires_at}

def get_subscription(app_user_id: str) -> dict:
    return _subscriptions.get(app_user_id, {"tier": "free", "expires_at": None})

def remove_subscription(app_user_id: str):
    _subscriptions.pop(app_user_id, None)


# ---- 事件追踪 ----
def track_event(event: str, user_id: str = ""):
    _maybe_snapshot()
    if event == "app_open":
        _daily["dau"].add(user_id)
    elif event == "purchase":
        _daily["purchases"] += 1
        # Estimate revenue based on purchase event
        global _revenue
        _revenue += 4.99  # rough average across monthly/annual/lifetime
    elif event == "hearts_depleted":
        _daily["hearts_depleted"] += 1
    elif event == "promo_shown":
        _daily["promo_shown"] += 1
    elif event == "daily_challenge_used":
        _daily["daily_challenge_used"] += 1


# ---- 看板数据 ----
def get_dashboard() -> dict:
    _maybe_snapshot()
    dau = len(_daily["dau"])
    hearts = _daily["hearts_depleted"]
    promos = _daily["promo_shown"]
    purchases = _daily["purchases"]

    # Conversion rates
    dau_to_hearts = f"{hearts/max(dau,1)*100:.1f}%" if dau else "—"
    hearts_to_promo = f"{promos/max(hearts,1)*100:.1f}%" if hearts else "—"
    promo_to_purchase = f"{purchases/max(promos,1)*100:.1f}%" if promos else "—"

    return {
        # Today
        "dau": dau,
        "hearts_depleted": hearts,
        "promo_shown": promos,
        "purchases": purchases,
        "daily_challenge_used": _daily["daily_challenge_used"],
        "total_subscribers": sum(1 for s in _subscriptions.values() if s["tier"] != "free"),
        # Conversion
        "dau_to_hearts": dau_to_hearts,
        "hearts_to_promo": hearts_to_promo,
        "promo_to_purchase": promo_to_purchase,
        # Revenue
        "revenue": round(_revenue, 2),
        # History
        "history": _history[:7],  # last 7 days
        "updated_at": datetime.now().isoformat(),
    }
