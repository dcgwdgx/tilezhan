import pytest


@pytest.mark.asyncio
async def test_daily_quest(client, auth_headers):
    response = await client.get("/api/v1/puzzles/daily", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "flashcards" in data
    assert len(data["flashcards"]) == 10


@pytest.mark.asyncio
async def test_flashcards_filtered(client, auth_headers):
    response = await client.get(
        "/api/v1/puzzles/flashcards?suite=man&count=5", headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 5
    for card in data:
        assert card["tile_id"].startswith("m")
