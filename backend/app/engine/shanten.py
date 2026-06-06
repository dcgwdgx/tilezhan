"""Shanten (向听数) Calculator — Riichi Mahjong

Core algorithm: recursive backtracking with pruning.
Hand representation: 34-element array (0-8=Man, 9-17=Pin, 18-26=Sou, 27-33=Honors).
"""

from dataclasses import dataclass
from typing import Optional

TERMINAL_INDICES = [0, 8, 9, 17, 18, 26] + list(range(27, 34))


class ShantenCalculator:
    """Calculate minimum shanten number for a given hand.

    The shanten number is the minimum number of tiles that need to be
    replaced to reach tenpai (ready hand). 0 = already tenpai.
    """

    def __init__(self, tile_ids: list[str]):
        if not tile_ids:
            raise ValueError("Tile list must not be empty")
        self.tiles34 = self._to_34_array(tile_ids)
        self._best: int = 999

    @staticmethod
    def _to_34_array(tile_ids: list[str]) -> list[int]:
        arr = [0] * 34
        suit_map = {'m': 0, 'p': 1, 's': 2, 'z': 3}
        for tid in tile_ids:
            suit_char = tid[0]
            num = int(tid[1:])
            if suit_char == 'z':
                idx = 27 + (num - 1)
            elif suit_char == 'm':
                idx = num - 1
            elif suit_char == 'p':
                idx = 9 + (num - 1)
            elif suit_char == 's':
                idx = 18 + (num - 1)
            else:
                raise ValueError(f"Invalid tile: {tid}")
            arr[idx] += 1
        return arr

    def calculate(self) -> int:
        self._best = 999

        # Chiitoitsu (七对子) shanten: 6 - (pair count)
        pairs = sum(1 for c in self.tiles34 if c >= 2)
        chiitoi = 6 - pairs
        self._best = min(self._best, chiitoi)

        # Kokushi musou (国士无双) shanten
        kokushi = self._kokushi_shanten()
        self._best = min(self._best, kokushi)

        # Standard 4 mentsu + 1 jantou
        self._search_melds(4, 1)
        return self._best

    def _kokushi_shanten(self) -> int:
        kinds = 0
        has_pair = False
        for i in TERMINAL_INDICES:
            if self.tiles34[i] > 0:
                kinds += 1
            if self.tiles34[i] >= 2:
                has_pair = True
        return 13 - kinds - (1 if has_pair else 0)

    def _count_isolated_and_partials(self) -> int:
        """Count tiles that are NOT part of complete melds or pairs.

        Returns an estimate of how many tiles are still "loose".
        """
        count = 0
        # Count tiles beyond what can form melds
        remaining = self.tiles34[:]
        # Greedy: first remove complete triplets
        for i in range(34):
            while remaining[i] >= 3:
                remaining[i] -= 3
        # Then remove sequences
        for i in range(27):
            if i % 9 <= 6:
                while remaining[i] > 0 and remaining[i+1] > 0 and remaining[i+2] > 0:
                    remaining[i] -= 1
                    remaining[i+1] -= 1
                    remaining[i+2] -= 1
        # Then remove pairs
        pairs_removed = 0
        for i in range(34):
            if remaining[i] >= 2 and pairs_removed < 1:
                remaining[i] -= 2
                pairs_removed += 1
        # Count remaining tiles
        return sum(remaining)

    def _search_melds(self, mentsu: int, jantou: int):
        """Recursive search for best meld + jantou arrangement."""
        # Estimate: need 2 tiles per missing mentsu, 1 per missing jantou
        # But partial melds reduce this
        partial = self._count_isolated_and_partials()

        # Heuristic: remaining work = partial tiles need to be replaced
        # Each meld can absorb 3 tiles, jantou absorbs 2
        needed = partial
        # The shanten from this position is roughly:
        #   needed / 2 (rounded up) - already formed melds
        est = max(0, (needed - mentsu * 3 - jantou * 2 + 1) // 2)
        self._best = min(self._best, max(0, est + (4 - mentsu)))

        if self._best == 0:
            return

        if mentsu == 0 and jantou == 0:
            self._best = 0
            return

        # Try forming a pair (jantou)
        if jantou == 1:
            for i in range(34):
                if self.tiles34[i] >= 2:
                    self.tiles34[i] -= 2
                    self._search_melds(mentsu, 0)
                    self.tiles34[i] += 2

        # Try forming a triplet
        if mentsu > 0:
            for i in range(34):
                if self.tiles34[i] >= 3:
                    self.tiles34[i] -= 3
                    self._search_melds(mentsu - 1, jantou)
                    self.tiles34[i] += 3

            # Try forming a sequence
            for i in range(27):
                if i % 9 <= 6:
                    if self.tiles34[i] > 0 and self.tiles34[i+1] > 0 and self.tiles34[i+2] > 0:
                        self.tiles34[i] -= 1
                        self.tiles34[i+1] -= 1
                        self.tiles34[i+2] -= 1
                        self._search_melds(mentsu - 1, jantou)
                        self.tiles34[i] += 1
                        self.tiles34[i+1] += 1
                        self.tiles34[i+2] += 1
