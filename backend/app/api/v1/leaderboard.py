"""
排行榜 API — Firestore 持久化全局 ELO 排名。

提供麻将牌识别竞赛的排行榜功能：
- GET  /leaderboard：获取全局 ELO 排名前 N 名
- POST /leaderboard/report：上报用户 ELO 分数

存储方式：
    Firestore collection `rankings`，文档 ID 为玩家名称。
    每个文档包含：{name, elo, streak, updated_at}。
    Firestore 不可用时降级为内存字典。

ELO 更新策略：
    仅保留每个玩家的最高 ELO 分数。
    若上报分数低于当前记录，静默忽略；
    仅当上报分数更高或玩家首次出现时才更新。
"""

from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException

from app.core.firebase import get_firestore

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])

# ============================================================
# Firestore 不可用时的内存降级存储
# ============================================================
_fallback: dict[str, dict] = {}
_firestore_unavailable = False


def _get_collection():
    """获取 Firestore rankings 集合引用，不可用时返回 None。"""
    db = get_firestore()
    if db is None:
        return None
    try:
        return db.collection("rankings")
    except Exception:
        return None


@router.get("")
@router.get("/")
async def get_leaderboard(limit: int = 100):
    """
    获取全局 ELO 排行榜的前 N 名。

    Query 参数：
        limit (int, 默认 100): 返回的最大条目数。

    Returns:
        dict: {"rankings": [...]}，每项包含：
            - rank (int): 排名（从 1 开始）
            - name (str): 玩家显示名称
            - elo (int): 当前最高 ELO 评分
            - streak (int): 连续正确回答次数
    """
    global _firestore_unavailable

    col = _get_collection()

    # ── Firestore 路径 ──
    if col is not None and not _firestore_unavailable:
        try:
            docs = (
                col.order_by("elo", direction="DESCENDING")
                .limit(limit)
                .stream()
            )
            rankings = []
            for i, doc in enumerate(docs):
                data = doc.to_dict()
                rankings.append({
                    "rank": i + 1,
                    "name": data.get("name", doc.id),
                    "elo": data.get("elo", 800),
                    "streak": data.get("streak", 0),
                })
            return {"rankings": rankings}
        except Exception:
            # Firestore 查询失败 → 标记不可用，降级到内存
            _firestore_unavailable = True

    # ── 内存降级路径 ──
    sorted_rankings = sorted(
        _fallback.items(), key=lambda x: x[1].get("elo", 800), reverse=True
    )[:limit]
    return {
        "rankings": [
            {
                "rank": i + 1,
                "name": name,
                "elo": data.get("elo", 800),
                "streak": data.get("streak", 0),
            }
            for i, (name, data) in enumerate(sorted_rankings)
        ]
    }


@router.post("/report")
async def report_score(name: str, elo: int = 800, streak: int = 0):
    """
    上报用户的 ELO 分数（由前端在每次测验后调用）。

    更新策略（仅保留最高分）：
    - 若玩家首次出现 → 直接写入
    - 若新分数 > 当前记录 → 更新为新分数
    - 若新分数 <= 当前记录 → 静默忽略

    Query 参数：
        name   (str):         玩家显示名称。
        elo    (int, 默认 800): 当前 ELO 评分。
        streak (int, 默认 0):  连续正确回答次数。

    Returns:
        dict: {"status": "ok"}
    """
    global _firestore_unavailable

    if not name or not name.strip():
        raise HTTPException(status_code=400, detail="name is required")

    name = name.strip()

    col = _get_collection()

    # ── Firestore 路径 ──
    if col is not None and not _firestore_unavailable:
        try:
            doc_ref = col.document(name)
            doc = doc_ref.get()

            if doc.exists:
                current = doc.to_dict()
                current_elo = current.get("elo", 800)
                if elo <= current_elo:
                    return {"status": "ok", "updated": False}
                # 更高分数 → 更新
                doc_ref.update({
                    "elo": elo,
                    "streak": streak,
                    "updated_at": datetime.now(timezone.utc),
                })
            else:
                # 新玩家 → 创建文档
                doc_ref.set({
                    "name": name,
                    "elo": elo,
                    "streak": streak,
                    "created_at": datetime.now(timezone.utc),
                    "updated_at": datetime.now(timezone.utc),
                })
            return {"status": "ok", "updated": True}
        except Exception:
            _firestore_unavailable = True
            # Fall through to in-memory fallback

    # ── 内存降级路径 ──
    if name not in _fallback or _fallback[name].get("elo", 800) < elo:
        _fallback[name] = {"elo": elo, "streak": streak}
        return {"status": "ok", "updated": True}
    return {"status": "ok", "updated": False}
