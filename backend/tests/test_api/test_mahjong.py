import pytest


@pytest.mark.asyncio
async def test_shanten(client, auth_headers):
    hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
    response = await client.post(
        "/api/v1/mahjong/shanten",
        json={"tiles": hand},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert "shanten" in response.json()


@pytest.mark.asyncio
async def test_ukeire(client, auth_headers):
    hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
    response = await client.post(
        "/api/v1/mahjong/ukeire",
        json={"tiles": hand},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) > 0
