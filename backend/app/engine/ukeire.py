"""Ukeire calculator for a closed 14-tile Japanese mahjong hand."""

from collections import Counter

from app.domain.models.tile import ALL_TILE_IDS
from app.engine.shanten import ShantenCalculator


class UkeireCalculator:
    """Calculate effective draws for every unique discard candidate."""

    def __init__(self, tile_ids: list[str]):
        if len(tile_ids) != 14:
            raise ValueError(f"Expected 14 tiles, got {len(tile_ids)}")

        # Validate IDs and the four-copy limit before a discard can hide an
        # otherwise invalid fifth copy.
        ShantenCalculator(tile_ids)
        self.tiles = list(tile_ids)
        self._visible_counts = Counter(self.tiles)

    def calculate(self) -> dict[str, dict]:
        results: dict[str, dict] = {}
        seen: set[str] = set()

        for index, discard_id in enumerate(self.tiles):
            if discard_id in seen:
                continue
            seen.add(discard_id)

            remaining = self.tiles[:index] + self.tiles[index + 1 :]
            base_shanten = ShantenCalculator(remaining).calculate()
            ukeire_types: list[str] = []
            ukeire_count = 0

            for test_id in ALL_TILE_IDS:
                # The selected discard is visible in the river, so availability
                # is based on all 14 originally visible tiles, not just the 13
                # tiles left in hand.
                available = 4 - self._visible_counts[test_id]
                if available <= 0:
                    continue

                new_shanten = ShantenCalculator(remaining + [test_id]).calculate()
                if new_shanten < base_shanten:
                    ukeire_types.append(test_id)
                    ukeire_count += available

            results[discard_id] = {
                "shanten_after": base_shanten,
                "ukeire_types": ukeire_types,
                "ukeire_count": ukeire_count,
            }

        return results
