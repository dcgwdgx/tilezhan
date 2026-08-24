import pytest

from app.engine.ukeire import UkeireCalculator


FALLBACK_HAND = [
    "m1", "m2", "m3", "m4", "m5", "m6", "p5", "p6",
    "p7", "p8", "p9", "z1", "z1", "z2",
]


def test_exact_fallback_ukeire_after_discarding_z2():
    result = UkeireCalculator(FALLBACK_HAND).calculate()["z2"]

    assert result["shanten_after"] == 0
    assert result["ukeire_types"] == ["p4", "p7"]
    assert result["ukeire_count"] == 7


def test_each_discard_uses_its_own_thirteen_tile_baseline():
    result = UkeireCalculator(FALLBACK_HAND).calculate()["m1"]

    assert result["shanten_after"] == 1
    assert "m1" in result["ukeire_types"]
    assert result["ukeire_count"] == 17


def test_ukeire_requires_exactly_fourteen_tiles():
    with pytest.raises(ValueError, match="Expected 14 tiles"):
        UkeireCalculator(FALLBACK_HAND[:-1])


def test_ukeire_rejects_five_copies():
    invalid_hand = ["m1"] * 5 + FALLBACK_HAND[:9]
    with pytest.raises(ValueError, match="Too many copies"):
        UkeireCalculator(invalid_hand)
