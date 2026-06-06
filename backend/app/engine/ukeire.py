"""Ukeire (进张数) Calculator — tile acceptance after discarding."""

from app.engine.shanten import ShantenCalculator
from app.domain.models.tile import ALL_TILE_IDS


class UkeireCalculator:
    """For a 14-tile hand, calculate tile acceptance after each discard."""

    def __init__(self, tile_ids: list[str]):
        if len(tile_ids) != 14:
            raise ValueError(f"Expected 14 tiles, got {len(tile_ids)}")
        self.tiles = tile_ids
        self._base_shanten = ShantenCalculator(tile_ids).calculate()

    def calculate(self) -> dict[str, dict]:
        results = {}
        seen: set[str] = set()

        for i, discard_id in enumerate(self.tiles):
            if discard_id in seen:
                continue
            seen.add(discard_id)

            remaining = self.tiles[:i] + self.tiles[i + 1:]
            ukeire_types: list[str] = []
            ukeire_count = 0

            for test_id in ALL_TILE_IDS:
                candidate = remaining + [test_id]
                shanten = ShantenCalculator(candidate).calculate()
                if shanten < self._base_shanten:
                    ukeire_types.append(test_id)
                    ukeire_count += 4 - self.tiles.count(test_id)

            results[discard_id] = {
                "shanten_after": ShantenCalculator(remaining).calculate(),
                "ukeire_types": ukeire_types,
                "ukeire_count": ukeire_count,
            }

        return results
