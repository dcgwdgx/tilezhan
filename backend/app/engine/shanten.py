"""Japanese mahjong shanten calculator for closed 13/14-tile hands.

Tile IDs use the project-wide suit-first convention: ``m1``-``m9``,
``p1``-``p9``, ``s1``-``s9``, and ``z1``-``z7``.

The returned value follows the conventional definition used by the client:

* ``-1``: complete hand
* ``0``: tenpai
* ``1``: one-shanten

The minimum across the standard shape, seven pairs, and thirteen orphans is
returned.
"""

from functools import lru_cache


TERMINAL_INDICES = (0, 8, 9, 17, 18, 26, *range(27, 34))


class ShantenCalculator:
    """Calculate the minimum shanten number for a list of tile IDs."""

    def __init__(self, tile_ids: list[str]):
        if not tile_ids:
            raise ValueError("Tile list must not be empty")
        self.tiles34 = self._to_34_array(tile_ids)

    @staticmethod
    def _to_34_array(tile_ids: list[str]) -> list[int]:
        counts = [0] * 34
        offsets = {"m": 0, "p": 9, "s": 18, "z": 27}

        for tile_id in tile_ids:
            if not isinstance(tile_id, str) or len(tile_id) != 2:
                raise ValueError(f"Invalid tile: {tile_id}")

            suit = tile_id[0]
            rank_text = tile_id[1]
            if suit not in offsets or rank_text not in "123456789":
                raise ValueError(f"Invalid tile: {tile_id}")

            rank = int(rank_text)
            max_rank = 7 if suit == "z" else 9
            if rank < 1 or rank > max_rank:
                raise ValueError(f"Invalid tile: {tile_id}")

            index = offsets[suit] + rank - 1
            counts[index] += 1
            if counts[index] > 4:
                raise ValueError(f"Too many copies of tile: {tile_id}")

        return counts

    def calculate(self) -> int:
        """Return the minimum standard, seven-pairs, or orphans shanten."""
        return min(
            self._standard_shanten(),
            self._chiitoitsu_shanten(),
            self._kokushi_shanten(),
        )

    def _standard_shanten(self) -> int:
        """Calculate shanten for the standard four-meld-and-pair shape."""

        @lru_cache(maxsize=None)
        def search(
            state: tuple[int, ...],
            melds: int,
            taatsu: int,
            has_pair: int,
        ) -> int:
            usable_taatsu = min(taatsu, 4 - melds)
            best = 8 - 2 * melds - usable_taatsu - has_pair

            first = next((i for i, count in enumerate(state) if count), None)
            if first is None:
                return best

            counts = list(state)

            # Leave this tile isolated so every decomposition remains reachable.
            counts[first] -= 1
            best = min(best, search(tuple(counts), melds, taatsu, has_pair))
            counts[first] += 1

            if melds < 4 and counts[first] >= 3:
                counts[first] -= 3
                best = min(best, search(tuple(counts), melds + 1, taatsu, has_pair))
                counts[first] += 3

            if (
                melds < 4
                and first < 27
                and first % 9 <= 6
                and counts[first + 1] > 0
                and counts[first + 2] > 0
            ):
                counts[first] -= 1
                counts[first + 1] -= 1
                counts[first + 2] -= 1
                best = min(best, search(tuple(counts), melds + 1, taatsu, has_pair))
                counts[first] += 1
                counts[first + 1] += 1
                counts[first + 2] += 1

            if not has_pair and counts[first] >= 2:
                counts[first] -= 2
                best = min(best, search(tuple(counts), melds, taatsu, 1))
                counts[first] += 2

            if taatsu < 4 - melds:
                if counts[first] >= 2:
                    counts[first] -= 2
                    best = min(best, search(tuple(counts), melds, taatsu + 1, has_pair))
                    counts[first] += 2

                if first < 27 and first % 9 <= 7 and counts[first + 1] > 0:
                    counts[first] -= 1
                    counts[first + 1] -= 1
                    best = min(best, search(tuple(counts), melds, taatsu + 1, has_pair))
                    counts[first] += 1
                    counts[first + 1] += 1

                if first < 27 and first % 9 <= 6 and counts[first + 2] > 0:
                    counts[first] -= 1
                    counts[first + 2] -= 1
                    best = min(best, search(tuple(counts), melds, taatsu + 1, has_pair))
                    counts[first] += 1
                    counts[first + 2] += 1

            return best

        return search(tuple(self.tiles34), 0, 0, 0)

    def _chiitoitsu_shanten(self) -> int:
        pair_count = sum(count >= 2 for count in self.tiles34)
        unique_count = sum(count > 0 for count in self.tiles34)
        return 6 - pair_count + max(0, 7 - unique_count)

    def _kokushi_shanten(self) -> int:
        unique_terminals = sum(self.tiles34[i] > 0 for i in TERMINAL_INDICES)
        has_pair = any(self.tiles34[i] >= 2 for i in TERMINAL_INDICES)
        return 13 - unique_terminals - int(has_pair)
