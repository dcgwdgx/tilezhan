"""Validation and regression tests for the shanten calculator."""

import random

import pytest

from app.engine.shanten import ShantenCalculator


@pytest.mark.parametrize("tile_id", ["1m", "m0", "m10", "m１", "z8", "xx"])
def test_rejects_noncanonical_tile_ids(tile_id):
    with pytest.raises(ValueError):
        ShantenCalculator([tile_id])


def test_empty_hand_is_rejected():
    with pytest.raises(ValueError):
        ShantenCalculator([])


def test_five_copies_are_rejected():
    with pytest.raises(ValueError, match="Too many copies"):
        ShantenCalculator(["m1"] * 5)


def test_four_copies_are_allowed():
    result = ShantenCalculator(["m1"] * 4).calculate()
    assert isinstance(result, int)


def test_order_does_not_change_shanten():
    hand = [
        "m1", "m2", "m3", "m4", "m5", "m6", "p2", "p3",
        "p5", "p6", "s1", "s1", "z1",
    ]
    expected = ShantenCalculator(hand).calculate()
    random.Random(20260824).shuffle(hand)
    assert ShantenCalculator(hand).calculate() == expected == 1


def test_calculation_does_not_mutate_input():
    hand = [
        "m1", "m2", "m3", "m4", "m5", "m6", "p2", "p3",
        "p4", "p5", "p6", "s1", "s1",
    ]
    original = list(hand)
    ShantenCalculator(hand).calculate()
    assert hand == original
