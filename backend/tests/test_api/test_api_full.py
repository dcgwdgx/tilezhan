"""Full API integration tests."""

import pytest


@pytest.mark.asyncio
async def test_health_check(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_user_profile(client, auth_headers):
    response = await client.get("/api/v1/user/profile", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "uid" in data
    assert "stats" in data
    assert "stamina" in data


@pytest.mark.asyncio
async def test_user_stamina(client, auth_headers):
    response = await client.get("/api/v1/user/stamina", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "hearts" in data
    assert "server_time" in data


@pytest.mark.asyncio
async def test_stamina_consume(client, auth_headers):
    import time
    response = await client.post(
        "/api/v1/user/stamina/consume",
        json={"hearts_before": 3, "client_timestamp": int(time.time() * 1000)},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["hearts"] == 2


@pytest.mark.asyncio
async def test_stamina_zero_rejected(client, auth_headers):
    import time
    response = await client.post(
        "/api/v1/user/stamina/consume",
        json={"hearts_before": 0, "client_timestamp": int(time.time() * 1000)},
        headers=auth_headers,
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_flashcards_manzu(client, auth_headers):
    response = await client.get("/api/v1/puzzles/flashcards?suite=man&count=5", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 5
    for card in data:
        assert card["tile_id"].startswith("m")


@pytest.mark.asyncio
async def test_flashcards_pinzu(client, auth_headers):
    response = await client.get("/api/v1/puzzles/flashcards?suite=sou&count=5", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 5
    for card in data:
        assert card["tile_id"].startswith("s")


@pytest.mark.asyncio
async def test_flashcards_invalid_suite(client, auth_headers):
    response = await client.get("/api/v1/puzzles/flashcards?suite=xxx&count=3", headers=auth_headers)
    assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_shanten_returns_int(client, auth_headers):
    hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
    response = await client.post("/api/v1/mahjong/shanten", json={"tiles": hand}, headers=auth_headers)
    assert response.status_code == 200
    assert isinstance(response.json()["shanten"], int)


@pytest.mark.asyncio
async def test_shanten_invalid_tile(client, auth_headers):
    response = await client.post("/api/v1/mahjong/shanten", json={"tiles": ["xx"]}, headers=auth_headers)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_ukeire_returns_dict(client, auth_headers):
    hand = ["m1","m1","m2","m3","m4","m5","m6","m7","m8","m9","m9","p1","p1","p1"]
    response = await client.post("/api/v1/mahjong/ukeire", json={"tiles": hand}, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) > 0


@pytest.mark.asyncio
async def test_ukeire_too_few_tiles(client, auth_headers):
    response = await client.post("/api/v1/mahjong/ukeire", json={"tiles": ["m1"]*13}, headers=auth_headers)
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_srs_review_due(client, auth_headers):
    response = await client.get("/api/v1/srs/review_due", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "count" in data


@pytest.mark.asyncio
async def test_srs_report(client, auth_headers):
    response = await client.post("/api/v1/srs/report", json={
        "tile_id": "m5", "quality": 4, "puzzle_type": "flashcard"
    }, headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["repetitions"] >= 1


@pytest.mark.asyncio
async def test_subscription_verify(client, auth_headers):
    response = await client.post("/api/v1/subscription/verify", json={}, headers=auth_headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_subscription_status(client, auth_headers):
    response = await client.get("/api/v1/subscription/status", headers=auth_headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_products_list(client, auth_headers):
    response = await client.get("/api/v1/products/", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "products" in data
    assert len(data["products"]) >= 2


@pytest.mark.asyncio
async def test_unauthorized_rejected(client):
    """Requests without auth token should be rejected"""
    response = await client.get("/api/v1/user/profile")
    assert response.status_code in (401, 403)
