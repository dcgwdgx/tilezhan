"""Puzzle Service API — Daily Quest, Flashcards, Nani-Kiru"""

from fastapi import APIRouter, Depends, Query
from app.api.deps import get_current_user
from app.domain.models.tile import ALL_TILES, VALID_TILE_IDS
import random

router = APIRouter(prefix="/puzzles", tags=["Puzzles"])


@router.get("/daily")
async def get_daily_quest(user: dict = Depends(get_current_user)):
    tiles = list(ALL_TILES.values())
    random.shuffle(tiles)
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
    tiles = list(ALL_TILES.values())
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
