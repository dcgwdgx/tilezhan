import pytest

from app.engine.shanten import ShantenCalculator


@pytest.mark.parametrize(
    "hand, expected",
    [
        (
            ["m1", "m2", "m3", "m4", "m5", "m6", "p2", "p3", "p4", "p5", "p6", "p7", "s1", "s1"],
            -1,
        ),
        (
            ["m1", "m2", "m3", "m4", "m5", "m6", "p2", "p3", "p4", "p5", "p6", "s1", "s1"],
            0,
        ),
        (
            ["m1", "m2", "m3", "m4", "m5", "m6", "p2", "p3", "p5", "p6", "s1", "s1", "z1"],
            1,
        ),
    ],
)
def test_standard_shanten_exact(hand, expected):
    assert ShantenCalculator(hand).calculate() == expected


def test_chiitoitsu_complete_is_minus_one():
    hand = [
        "m1", "m1", "m2", "m2", "m4", "m4", "p1", "p1",
        "p3", "p3", "s5", "s5", "z1", "z1",
    ]
    assert ShantenCalculator(hand).calculate() == -1


def test_chiitoitsu_tenpai_is_zero():
    hand = [
        "m1", "m1", "m2", "m2", "m4", "m4", "p1", "p1",
        "p3", "p3", "s5", "s5", "z1",
    ]
    assert ShantenCalculator(hand).calculate() == 0


def test_chiitoitsu_requires_seven_distinct_tile_types():
    hand = [
        "m1", "m1", "m1", "m1", "m2", "m2", "m3", "m3",
        "p1", "p1", "p2", "p2", "s1", "s1",
    ]
    assert ShantenCalculator(hand).calculate() == 1


def test_kokushi_complete_is_minus_one():
    hand = [
        "m1", "m9", "p1", "p9", "s1", "s9", "z1", "z2",
        "z3", "z4", "z5", "z6", "z7", "z1",
    ]
    assert ShantenCalculator(hand).calculate() == -1


def test_kokushi_thirteen_sided_tenpai_is_zero():
    hand = [
        "m1", "m9", "p1", "p9", "s1", "s9", "z1", "z2",
        "z3", "z4", "z5", "z6", "z7",
    ]
    assert ShantenCalculator(hand).calculate() == 0
