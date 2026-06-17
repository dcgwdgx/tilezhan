"""
订阅状态存储 + 分析数据 — 内存 KV + 时间序列。

本模块为 TileZhan 后端的订阅和分析提供内存级数据存储，
设计目标为快速原型验证。生产环境应迁移至持久化数据库。

数据结构：
- _subscriptions: app_user_id → {tier, expires_at}  订阅状态字典
- _daily: 今日实时计数器（DAU、购买数、心耗尽数等）
- _history: 每日零点快照列表 [DAU, 购买, 心耗尽, 促销, 挑战, 付费用户数, 收入]
- _revenue: 估算收入累计（美元）

每日快照机制：
    通过 _maybe_snapshot() 检测日期变更：
    - 当天首次调用 → 将昨天的数据快照存入 _history
    - 同一天内多次调用 → 无操作
    - 计数器归零开始新一天统计

警告：
    所有数据仅存于内存，服务重启后全部丢失。
    生产环境必须迁移至 Firestore / PostgreSQL。
"""

from datetime import datetime, date
from typing import Optional
from collections import defaultdict

# ---- 订阅状态存储 ----
# 键为 app_user_id，值为 {"tier": str, "expires_at": Optional[str]}
_subscriptions: dict[str, dict] = {}

# ---- 今日实时计数器 ----
# dau 使用 set 实现去重；其余指标为递增计数器
_daily: dict = {
    "dau": set(),
    "purchases": 0,
    "hearts_depleted": 0,
    "promo_shown": 0,
    "daily_challenge_used": 0,
}
_last_snapshot_date: str = ""  # ISO 日期字符串，用于检测日期变更

# ---- 历史每日快照 ----
# 按时间倒序排列（最新的在前），保留最近 7 天用于看板展示
_history: list[dict] = []  # newest first

# ---- 估算收入 ----
# 每次购买事件 +$4.99（月费/年费/买断的平均估算值）
_revenue: float = 0.0  # cumulative


def _maybe_snapshot():
    """
    日期变更时将今日数据存入 _history 并清零计数器。

    调用时机：每次 track_event() 和 get_dashboard() 调用时。
    逻辑：
    1. 检查当天日期是否与上次快照日期相同
    2. 若相同 → 直接返回（同日无需快照）
    3. 若不同 → 将前一日数据快照存入 _history 头部，重置所有计数器
    """
    global _last_snapshot_date
    today = date.today().isoformat()
    if _last_snapshot_date and _last_snapshot_date == today:
        return  # 今天已经切过日期，无需再切
    if _last_snapshot_date:  # 不是首次运行 → 保存昨天数据
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
    # 重置为今天的初始状态
    _last_snapshot_date = today
    _daily["dau"] = set()
    _daily["purchases"] = 0
    _daily["hearts_depleted"] = 0
    _daily["promo_shown"] = 0
    _daily["daily_challenge_used"] = 0


# ---- 订阅操作函数 ----

def set_subscription(app_user_id: str, tier: str, expires_at: Optional[str] = None):
    """
    设置（创建或更新）用户的订阅状态。

    Args:
        app_user_id: 用户标识符。
        tier: 订阅等级，如 "free"、"premium"、"lifetime"。
        expires_at: 可选，订阅过期时间的 ISO 字符串或毫秒时间戳。
    """
    _subscriptions[app_user_id] = {"tier": tier, "expires_at": expires_at}


def get_subscription(app_user_id: str) -> dict:
    """
    获取用户的订阅状态。

    Args:
        app_user_id: 用户标识符。

    Returns:
        dict: 包含 tier 和 expires_at 的字典。
              若用户无记录，默认返回 {"tier": "free", "expires_at": None}。
    """
    return _subscriptions.get(app_user_id, {"tier": "free", "expires_at": None})


def remove_subscription(app_user_id: str):
    """
    移除用户的订阅记录（取消/过期时调用）。

    Args:
        app_user_id: 要移除订阅的用户标识符。
    """
    _subscriptions.pop(app_user_id, None)


# ---- 事件追踪函数 ----

def track_event(event: str, user_id: str = ""):
    """
    追踪用户行为和业务事件。

    每次调用先执行 _maybe_snapshot() 以确保日期切换。

    支持的事件类型：
    - "app_open": 应用打开 → DAU +1（user_id 去重）
    - "purchase": 购买事件 → purchases +1, revenue +$4.99
    - "hearts_depleted": 心耗尽 → hearts_depleted +1
    - "promo_shown": 促销展示 → promo_shown +1
    - "daily_challenge_used": 每日挑战完成 → daily_challenge_used +1

    Args:
        event: 事件类型字符串。
        user_id: 触发事件的用户标识符（用于 DAU 去重）。
    """
    _maybe_snapshot()
    if event == "app_open":
        _daily["dau"].add(user_id)  # set 自动去重
    elif event == "purchase":
        _daily["purchases"] += 1
        # 收入估算：取月费/年费/买断的粗略平均值
        global _revenue
        _revenue += 4.99  # rough average across monthly/annual/lifetime
    elif event == "hearts_depleted":
        _daily["hearts_depleted"] += 1
    elif event == "promo_shown":
        _daily["promo_shown"] += 1
    elif event == "daily_challenge_used":
        _daily["daily_challenge_used"] += 1


# ---- 看板数据聚合 ----

def get_dashboard() -> dict:
    """
    生成管理仪表盘所需的聚合数据。

    返回值包含：
    - 今日核心指标：DAU、心耗尽数、促销展示数、购买数、挑战使用数、付费用户数
    - 转化漏斗：DAU → 心耗尽 → 促销 → 购买（每步转化率百分比）
    - 估算收入（美元，保留两位小数）
    - 最近 7 天历史快照
    - 数据更新时间

    Returns:
        dict: 结构化仪表盘数据，可直接序列化为 JSON 返回前端。
    """
    _maybe_snapshot()
    dau = len(_daily["dau"])
    hearts = _daily["hearts_depleted"]
    promos = _daily["promo_shown"]
    purchases = _daily["purchases"]

    # 计算转化漏斗各步转化率（避免除零）
    dau_to_hearts = f"{hearts / max(dau, 1) * 100:.1f}%" if dau else "—"
    hearts_to_promo = f"{promos / max(hearts, 1) * 100:.1f}%" if hearts else "—"
    promo_to_purchase = f"{purchases / max(promos, 1) * 100:.1f}%" if promos else "—"

    return {
        # 今日核心指标
        "dau": dau,
        "hearts_depleted": hearts,
        "promo_shown": promos,
        "purchases": purchases,
        "daily_challenge_used": _daily["daily_challenge_used"],
        "total_subscribers": sum(1 for s in _subscriptions.values() if s["tier"] != "free"),
        # 转化漏斗
        "dau_to_hearts": dau_to_hearts,
        "hearts_to_promo": hearts_to_promo,
        "promo_to_purchase": promo_to_purchase,
        # 收入
        "revenue": round(_revenue, 2),
        # 最近 7 天历史
        "history": _history[:7],  # last 7 days
        "updated_at": datetime.now().isoformat(),
    }
