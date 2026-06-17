"""
麻将计算引擎 API — 向听数与进张数计算。

提供基于日麻规则的牌效计算端点：
- POST /mahjong/shanten：计算当前手牌的向听数
- POST /mahjong/ukeire：计算 14 张手牌每张弃牌后的有效进张

请求格式：
    {"tiles": ["m1","m2","m3","p1","p2","p3","s1","s2","s3","z1","z1","z1","z2","z2"]}

输入校验：
    使用 Pydantic field_validator 在请求体解析阶段验证每张牌 ID
    是否为合法的 34 种牌之一（m1-m9, p1-p9, s1-s9, z1-z7）。
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from app.api.deps import get_current_user
from app.domain.models.tile import VALID_TILE_IDS
from app.engine.shanten import ShantenCalculator
from app.engine.ukeire import UkeireCalculator

router = APIRouter(prefix="/mahjong", tags=["Mahjong Engine"])


class TilesRequest(BaseModel):
    """
    麻将牌列表请求体。

    Attributes:
        tiles: 牌 ID 列表，每项必须是 34 种合法牌之一。
    """

    tiles: list[str]

    @field_validator("tiles")
    @classmethod
    def validate_tiles(cls, v: list[str]) -> list[str]:
        """
        Pydantic 字段校验器 — 验证每张牌 ID 是否合法。

        在请求解析阶段执行，不合法时直接返回 422 错误，
        无需进入业务逻辑层。

        Args:
            v: 客户端提交的牌 ID 列表。

        Returns:
            list[str]: 通过验证的原始列表。

        Raises:
            ValueError: 存在不在 VALID_TILE_IDS 中的牌 ID。
        """
        for tid in v:
            if tid not in VALID_TILE_IDS:
                raise ValueError(f"Invalid tile ID: {tid}")
        return v


@router.post("/shanten")
async def calculate_shanten(req: TilesRequest, user: dict = Depends(get_current_user)):
    """
    计算当前手牌的向听数。

    向听数定义为距离听牌（Tenpai）还需更换的最小牌数。
    - 0 = 已听牌
    - 1 = 一向听
    - 以此类推

    支持三种手牌类型：
    - 标准型（4 面子 + 1 雀头）
    - 七对子（Chiitoitsu）
    - 国士无双（Kokushi Musou）

    Args:
        req: 包含 tiles 字段的请求体。
        user: 当前用户信息。

    Returns:
        dict: {"shanten": <int>} 最小向听数。
    """
    return {"shanten": ShantenCalculator(req.tiles).calculate()}


@router.post("/ukeire")
async def calculate_ukeire(req: TilesRequest, user: dict = Depends(get_current_user)):
    """
    计算 14 张手牌每张弃牌后的有效进张数。

    对每张唯一的弃牌候选，遍历所有可能摸到的牌，
    统计能使向听数降低的牌的种类和数量。

    前置条件：
    - 必须恰好 14 张牌（完整手牌 + 1 张待弃牌）
    - 不足或超出均返回 400 错误

    Args:
        req: 包含恰好 14 张牌 ID 的请求体。
        user: 当前用户信息。

    Returns:
        dict: 以弃牌 ID 为键的结果字典，每项包含：
            - shanten_after: 弃牌后的向听数
            - ukeire_types: 有效进张的牌 ID 列表
            - ukeire_count: 有效进张的总枚数（考虑已持有数量）

    Raises:
        HTTPException 400: 手牌数量不等于 14。
    """
    if len(req.tiles) != 14:
        raise HTTPException(status_code=400, detail="Exactly 14 tiles required")
    return UkeireCalculator(req.tiles).calculate()
