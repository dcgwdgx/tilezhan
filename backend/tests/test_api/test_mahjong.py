import pytest


TENPAI_HAND = [
    "m1", "m2", "m3", "m4", "m5", "m6", "p2", "p3",
    "p4", "p5", "p6", "s1", "s1",
]

FALLBACK_HAND = [
    "m1", "m2", "m3", "m4", "m5", "m6", "p5", "p6",
    "p7", "p8", "p9", "z1", "z1", "z2",
]


@pytest.mark.asyncio
async def test_shanten_api_returns_exact_tenpai_value(client, auth_headers):
    response = await client.post(
        "/api/v1/mahjong/shanten",
        json={"tiles": TENPAI_HAND},
        headers=auth_headers,
    )

    assert response.status_code == 200
    assert response.json() == {"shanten": 0}


@pytest.mark.asyncio
async def test_shanten_api_returns_minus_one_for_complete_hand(client, auth_headers):
    response = await client.post(
        "/api/v1/mahjong/shanten",
        json={"tiles": TENPAI_HAND + ["p7"]},
        headers=auth_headers,
    )

    assert response.status_code == 200
    assert response.json() == {"shanten": -1}


@pytest.mark.asyncio
@pytest.mark.parametrize("count", [0, 12, 15])
async def test_shanten_api_rejects_non_hand_lengths(client, auth_headers, count):
    tiles = (["m1", "m2", "m3", "m4"] * 4)[:count]
    response = await client.post(
        "/api/v1/mahjong/shanten",
        json={"tiles": tiles},
        headers=auth_headers,
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_shanten_api_rejects_five_copies(client, auth_headers):
    hand = ["m1"] * 5 + ["m2", "m3", "m4", "p1", "p2", "p3", "s1", "s2"]
    response = await client.post(
        "/api/v1/mahjong/shanten",
        json={"tiles": hand},
        headers=auth_headers,
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_shanten_api_rejects_number_first_tile_id(client, auth_headers):
    hand = list(TENPAI_HAND)
    hand[0] = "1m"
    response = await client.post(
        "/api/v1/mahjong/shanten",
        json={"tiles": hand},
        headers=auth_headers,
    )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_ukeire_api_returns_exact_fallback_result(client, auth_headers):
    response = await client.post(
        "/api/v1/mahjong/ukeire",
        json={"tiles": FALLBACK_HAND},
        headers=auth_headers,
    )

    assert response.status_code == 200
    assert response.json()["z2"] == {
        "shanten_after": 0,
        "ukeire_types": ["p4", "p7"],
        "ukeire_count": 7,
    }


@pytest.mark.asyncio
async def test_ukeire_api_requires_fourteen_tiles(client, auth_headers):
    response = await client.post(
        "/api/v1/mahjong/ukeire",
        json={"tiles": TENPAI_HAND},
        headers=auth_headers,
    )

    assert response.status_code == 400
