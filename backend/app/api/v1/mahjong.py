"""Mahjong Engine API — Shanten, Ukeire, Hand Calculation"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from app.api.deps import get_current_user
from app.domain.models.tile import VALID_TILE_IDS
from app.engine.shanten import ShantenCalculator
from app.engine.ukeire import UkeireCalculator

router = APIRouter(prefix="/mahjong", tags=["Mahjong Engine"])


class TilesRequest(BaseModel):
    tiles: list[str]

    @field_validator("tiles")
    @classmethod
    def validate_tiles(cls, v: list[str]) -> list[str]:
        for tid in v:
            if tid not in VALID_TILE_IDS:
                raise ValueError(f"Invalid tile ID: {tid}")
        return v


@router.post("/shanten")
async def calculate_shanten(req: TilesRequest, user: dict = Depends(get_current_user)):
    return {"shanten": ShantenCalculator(req.tiles).calculate()}


@router.post("/ukeire")
async def calculate_ukeire(req: TilesRequest, user: dict = Depends(get_current_user)):
    if len(req.tiles) != 14:
        raise HTTPException(status_code=400, detail="Exactly 14 tiles required")
    return UkeireCalculator(req.tiles).calculate()
