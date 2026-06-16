"""排行榜 API — 全局 ELO 排名（内存存储，生产环境应迁移到 DB）。"""

from fastapi import APIRouter

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])

# 内存排行榜数据
_rankings = {}


@router.get("")
@router.get("/")
async def get_leaderboard(limit: int = 100):
    """返回全局 ELO 排名前 [limit] 名。"""
    sorted_rankings = sorted(
        _rankings.items(), key=lambda x: x[1].get("elo", 800), reverse=True
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
    """上报用户 ELO 分数（前端每次答题后调用）。"""
    if name not in _rankings or _rankings[name].get("elo", 800) < elo:
        _rankings[name] = {"elo": elo, "streak": streak}
    return {"status": "ok"}
