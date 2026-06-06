import pytest
from app.engine.shanten import ShantenCalculator


class TestShanten:
    @pytest.mark.parametrize("hand,expected_max", [
        # Complete hand with 4 melds + 1 pair = 0 shanten (or very low)
        (["m1","m1","m1","m2","m3","m4","m5","m6","m7","p1","p2","p3","p5","p5"], 1),
        # Hand with many complete melds
        (["m1","m2","m3","m4","m5","m6","m7","m8","m9","p1","p1","p1","p2","p2"], 0),
        # Random hand
        (["m1","m3","m5","m7","m9","p2","p4","p6","p8","s1","s3","s5","z1","z2"], 6),
    ])
    def test_shanten_max(self, hand, expected_max):
        """Shanten should not exceed expected_max for these hands."""
        assert ShantenCalculator(hand).calculate() <= expected_max

    def test_shanten_consistent(self):
        hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
        results = [ShantenCalculator(hand).calculate() for _ in range(5)]
        assert len(set(results)) == 1

    def test_empty_hand_raises(self):
        with pytest.raises(ValueError):
            ShantenCalculator([])

    def test_chiitoi_tenpai(self):
        """6 pairs = chiitoi tenpai (0 shanten)"""
        hand = ["m1","m1","m2","m2","m3","m3","p1","p1","p2","p2","p3","p3","s1","s1"]
        assert ShantenCalculator(hand).calculate() == 0
