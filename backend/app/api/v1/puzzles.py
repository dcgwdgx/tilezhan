"""
每日任务与闪卡 API — 谜题服务核心端点。

提供两个主要端点：
- GET /puzzles/daily：每日混合任务（闪卡 + 何切 + SRS 复习）
- GET /puzzles/flashcards：按花色筛选的闪卡列表

数据源：
    所有牌数据来自 app.domain.models.tile.ALL_TILES，
    包含 34 张牌的完整助记信息（emoji、名称、标语、描述、中文描述）。
    当前版本随机抽取，生产环境应改为基于用户的进度和 SRS 算法推荐。
"""

from fastapi import APIRouter, Depends, Query
from app.api.deps import get_current_user
from app.domain.models.tile import ALL_TILES, VALID_TILE_IDS
import random

router = APIRouter(prefix="/puzzles", tags=["Puzzles"])


@router.get("/daily")
async def get_daily_quest(user: dict = Depends(get_current_user)):
    """
    获取每日混合任务。

    返回三部分内容：
    - flashcards: 随机抽取 10 张牌的闪卡数据（id、label、mnemonic）
    - nanikiru: 何切问题（当前返回空列表，待实现）
    - srs_review: 待复习的 SRS 条目（当前返回空列表，待实现）

    生产环境应使用确定性随机（基于日期种子），
    确保同一用户当日获取到相同的每日任务。

    Args:
        user: 通过依赖注入获取的当前用户信息。

    Returns:
        dict: 包含 flashcards、nanikiru、srs_review 三个字段。
    """
    tiles = list(ALL_TILES.values())
    random.shuffle(tiles)
    # 取前 10 张牌生成闪卡数据
    flashcards = [
        {
            "tile_id": t.id,
            "label": t.label,
            "mnemonic": t.mnemonic,
        }
        for t in tiles[:10]
    ]
    return {
        "flashcards": flashcards,
        "nanikiru": [],
        "srs_review": [],
    }


@router.get("/flashcards")
async def get_flashcards(
    suite: str = Query("all", pattern="^(all|man|pin|sou|honor)$"),
    count: int = Query(10, ge=5, le=20),
    user: dict = Depends(get_current_user),
):
    """
    按花色筛选获取闪卡列表。

    支持按麻将花色过滤：
    - "all": 全部 34 张牌
    - "man": 仅万子（Manzu）1-9
    - "pin": 仅筒子（Pinzu）1-9
    - "sou": 仅条子（Souzu）1-9
    - "honor": 仅字牌（风牌 + 三元牌）共 7 张

    Args:
        suite: 花色筛选参数，默认 "all"。
        count: 返回数量（5-20），默认 10。
        user: 当前用户信息。

    Returns:
        list[dict]: 闪卡列表，每项包含 tile_id、label、mnemonic。
    """
    tiles = list(ALL_TILES.values())

    # 按花色过滤
    if suite == "man":
        tiles = [t for t in tiles if t.suit.value == "man"]
    elif suite == "pin":
        tiles = [t for t in tiles if t.suit.value == "pin"]
    elif suite == "sou":
        tiles = [t for t in tiles if t.suit.value == "sou"]
    elif suite == "honor":
        tiles = [t for t in tiles if t.suit.value in ("wind", "dragon")]

    random.shuffle(tiles)
    selected = tiles[:min(count, len(tiles))]
    return [
        {
            "tile_id": t.id,
            "label": t.label,
            "mnemonic": t.mnemonic,
        }
        for t in selected
    ]
