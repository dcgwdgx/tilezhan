from app.engine.ukeire import UkeireCalculator


def test_ukeire_returns_all_discards():
    hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
    result = UkeireCalculator(hand).calculate()
    assert len(result) > 0
    for discard_id, data in result.items():
        assert "shanten_after" in data
        assert "ukeire_count" in data
        assert "ukeire_types" in data


def test_ukeire_requires_exactly_14():
    import pytest
    with pytest.raises(ValueError):
        UkeireCalculator(["m1"] * 13)
