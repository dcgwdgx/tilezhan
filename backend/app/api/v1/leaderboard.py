"""
排行榜 API — 全局 ELO 排名。

提供麻将牌识别竞赛的排行榜功能：
- GET /leaderboard：获取全局 ELO 排名前 N 名
- POST /leaderboard/report：上报用户 ELO 分数

存储方式：
    使用内存字典 (_rankings) 存储排名数据。
    键为玩家名称，值为 {"elo": int, "streak": int}。

重要警告：
    内存存储在服务重启后数据全部丢失。
    生产环境必须迁移至持久化数据库（如 Firestore、PostgreSQL），
    并考虑添加 Redis 缓存层以应对高并发读取。

ELO 更新策略：
    仅保留每个玩家的最高 ELO 分数。
    若上报分数低于当前记录，静默忽略；
    仅当上报分数更高或玩家首次出现时才更新。
"""

from fastapi import APIRouter

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])

# ============================================================
# 内存排行榜存储
#
# 结构: dict[str, dict]  — 玩家名 → {"elo": int, "streak": int}
#
# 警告：服务重启后数据全部丢失。生产环境必须迁移到持久化 DB。
# ============================================================
_rankings = {}


@router.get("")
@router.get("/")
async def get_leaderboard(limit: int = 100):
    """
    获取全局 ELO 排行榜的前 N 名。

    按 ELO 分数降序排列，取前 [limit] 个条目。

    Query 参数：
        limit (int, 默认 100): 返回的最大条目数。

    Returns:
        dict: {"rankings": [...]}，每项包含：
            - rank (int): 排名（从 1 开始）
            - name (str): 玩家显示名称
            - elo (int): 当前最高 ELO 评分
            - streak (int): 连续正确回答次数

    注意：
        数据来自内存字典，服务重启后排名重置。
    """
    # 按 ELO 降序排列，取前 limit 名
    sorted_rankings = sorted(
        _rankings.items(), key=lambda x: x[1].get("elo", 800), reverse=True
    )[:limit]

    # 构建排名响应列表（rank 从 1 开始计数）
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

    更新策略（Last-Write-Wins 但仅保留最高分）：
    - 若玩家首次出现 → 直接写入
    - 若新分数 > 当前记录 → 更新为新分数
    - 若新分数 <= 当前记录 → 静默忽略

    Query 参数：
        name   (str):         玩家显示名称。
        elo    (int, 默认 800): 当前 ELO 评分。
        streak (int, 默认 0):  连续正确回答次数。

    Returns:
        dict: {"status": "ok"}

    注意：
        当前无身份验证，任何客户端可以任意名称上报。
        生产环境应绑定 Firebase UID 并进行身份校验。
    """
    # 仅当新 ELO 高于存储值时才更新
    if name not in _rankings or _rankings[name].get("elo", 800) < elo:
        _rankings[name] = {"elo": elo, "streak": streak}
    return {"status": "ok"}
