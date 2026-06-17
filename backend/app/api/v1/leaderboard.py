"""排行榜 API — 全局 ELO 排名（内存存储，生产环境应迁移到 DB）。"""

from fastapi import APIRouter

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])

# 内存排行榜数据
#
# In-memory ranking store (dict: name -> {elo, streak}).
# CAVEAT: Data is lost on server restart. Migrate to a persistent DB for production.
#
_rankings = {}


@router.get("")
@router.get("/")
async def get_leaderboard(limit: int = 100):
    """
    Return the global ELO leaderboard, top [limit] entries.

    Query params:
        limit (int, default 100): Max number of entries to return.

    Returns:
        {"rankings": [{"rank": int, "name": str, "elo": int, "streak": int}, ...]}

    CAVEAT: Rankings are held in an in-memory dict and will reset on server restart.
    """
    # Sort all entries by ELO descending, then take the top [limit].
    sorted_rankings = sorted(
        _rankings.items(), key=lambda x: x[1].get("elo", 800), reverse=True
    )[:limit]

    # Build the response list with computed rank positions (1-based).
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
    Report a user's ELO score (called by the frontend after each quiz).

    Query params:
        name  (str):       Player display name.
        elo   (int, default 800): Current ELO rating.
        streak (int, default 0):  Consecutive correct answer streak.

    Returns:
        {"status": "ok"}

    Only the highest ELO per player is kept — lower scores are silently ignored.
    CAVEAT: Stored in memory; all rankings are lost on server restart.
    """
    # Update the in-memory entry only if the new ELO beats the stored value.
    if name not in _rankings or _rankings[name].get("elo", 800) < elo:
        _rankings[name] = {"elo": elo, "streak": streak}
    return {"status": "ok"}
