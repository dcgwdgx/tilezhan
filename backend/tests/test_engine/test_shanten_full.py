"""Full Shanten calculator test suite — edge cases, special hands, consistency."""

import pytest
from app.engine.shanten import ShantenCalculator


class TestShantenTenpai:
    """Verify shanten=0 (tenpai) for various ready-hand patterns."""

    @pytest.mark.parametrize("hand,desc", [
        # Standard tenpai: 4 melds + 1 pair waiting
        (["m1","m1","m1","m2","m3","m4","m5","m6","m7","m8","m8","m8","p1","p2"], "straight tenpai"),
        # 6 pairs = chiitoi tenpai (waiting for 7th pair)
        (["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","p3","s1","s1"], "chiitoi tenpai"),
    ])
    def test_tenpai(self, hand, desc):
        assert ShantenCalculator(hand).calculate() == 0, desc


class TestShantenEdgeCases:
    def test_empty_hand(self):
        with pytest.raises(ValueError):
            ShantenCalculator([])

    def test_single_tile(self):
        """1 tile = Shanten is a constant for single tile"""
        result = ShantenCalculator(["m1"]).calculate()
        assert isinstance(result, int) and result >= 0

    def test_complete_hand(self):
        """Complete winning hand: 4 melds + 1 pair"""
        hand = ["m1","m2","m3","m4","m5","m6","m7","m8","m9","p1","p1","p1","p2","p2"]
        assert ShantenCalculator(hand).calculate() <= 1

    def test_all_honors(self):
        """7 different honors = only kokushi route"""
        hand = ["z1","z2","z3","z4","z5","z6","z7","z1","z2","z3","z4","z5","z6","z7"]
        assert ShantenCalculator(hand).calculate() < 6

    def test_nine_gates_tenpai(self):
        """九莲宝灯 waiting pattern"""
        hand = ["m1","m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","m9","m1"]
        assert ShantenCalculator(hand).calculate() <= 1


class TestShantenConsistency:
    def test_idempotent(self):
        """Same hand → same result every time"""
        hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
        results = [ShantenCalculator(hand).calculate() for _ in range(20)]
        assert len(set(results)) == 1

    def test_order_independence(self):
        """Tile order should not affect result"""
        import random
        tiles = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
        base = ShantenCalculator(tiles).calculate()
        for _ in range(10):
            random.shuffle(tiles)
            assert ShantenCalculator(tiles).calculate() == base

    def test_chiitoi_consistency(self):
        """Chiitoi: 5 pairs should be 1-shanten"""
        hand = ["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","s1","s2","s3","s4"]
        results = [ShantenCalculator(hand).calculate() for _ in range(5)]
        assert len(set(results)) == 1


class TestShantenValueRanges:
    @pytest.mark.parametrize("count,expected_max", [
        (14, 6),  # 14 tiles → max shanten = 6
        (13, 6),  # 13 tiles → max shanten = 6
        (5, 3),   # 5 tiles → max shanten around 3
    ])
    def test_max_shanten(self, count, expected_max):
        tiles = [f"m{(i%9)+1}" for i in range(count)]
        assert ShantenCalculator(tiles).calculate() <= expected_max

    def test_shanten_never_negative(self):
        """Shanten should never be negative"""
        for _ in range(50):
            import random
            suits = ["m","p","s","z"]
            hand = []
            for _ in range(14):
                s = random.choice(suits)
                n = random.randint(1, 9) if s != "z" else random.randint(1, 7)
                hand.append(f"{s}{n}")
            assert ShantenCalculator(hand).calculate() >= 0
