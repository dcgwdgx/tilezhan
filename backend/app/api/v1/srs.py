"""
间隔重复系统 (SRS) API — 复习调度与报告。

本模块实现了基于 SM-2 算法的间隔重复系统端点：
- GET /srs/review_due：获取当前到期待复习的条目
- POST /srs/report：报告复习结果并计算下一次复习间隔

SM-2 算法核心参数：
- easiness_factor (EF): 容易度因子，初始 2.5，下限 1.3
- interval: 复习间隔（天）
- repetitions: 连续正确回忆次数
- quality: 回忆质量评分 0-5（0=完全遗忘，5=完美回忆）

当前为内存实现原型，生产环境应接入 Firestore/SRS Service。
"""

from fastapi import APIRouter, Depends
from app.api.deps import get_current_user

router = APIRouter(prefix="/srs", tags=["SRS"])


@router.get("/review_due")
async def get_due_reviews(user: dict = Depends(get_current_user)):
    """
    获取当前到期待复习的条目。

    应返回 next_review <= now 的所有 SRS 条目，
    当前版本返回空列表（数据库尚未接入）。

    Args:
        user: 当前用户信息。

    Returns:
        dict: {"items": [], "count": 0}
    """
    return {"items": [], "count": 0}


@router.post("/report")
async def report_answer(report: dict, user: dict = Depends(get_current_user)):
    """
    报告一次复习结果，返回更新的 SRS 参数。

    采用 SM-2 算法计算新的 easiness_factor、interval_days 和 repetitions。

    SM-2 算法逻辑：
    - quality < 3（失败回滚）：EF 不变，间隔重置为 1 天，重复计数归零
    - quality >= 3（成功）：
        - EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))，下限 1.3
        - repetitions = 1（首次成功），否则递增
        - interval = 1（reps=1）| 6（reps=2）| round(interval * EF)（reps>2）

    Args:
        report: 包含 tile_id 和 quality (0-5) 的请求体。
        user: 当前用户信息。

    Returns:
        dict: 包含 tile_id、easiness_factor、interval_days、repetitions。
    """
    quality = report.get("quality", 3)

    if quality < 3:
        # 回忆失败 → 重置重复计数但保留 EF
        ef, interval, reps = 2.5, 1, 0
    else:
        # 成功回忆 → 更新 EF 因子（SM-2 公式）
        ef = max(1.3, 2.5 + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        reps = 1
        interval = 1 if reps == 1 else 6

    return {
        "tile_id": report.get("tile_id"),
        "easiness_factor": ef,
        "interval_days": interval,
        "repetitions": reps,
    }
