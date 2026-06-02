import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_story_generate_requires_authentication():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/api/v1/story/generate", json={"observation_record_id": "not-a-uuid"})

    assert response.status_code == 401
    assert response.json()["code"] == 401


@pytest.mark.asyncio
async def test_rules_create_requires_authentication():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/rules/create",
            json={
                "name": "default",
                "dsl": {"when": {"event_type": ["课堂表现"]}, "then": {"story_style": "warm"}},
            },
        )

    assert response.status_code == 401
    assert response.json()["code"] == 401
