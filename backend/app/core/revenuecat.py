"""RevenueCat REST API client — server-side subscription verification."""

import httpx
from app.config import settings


class RevenueCatClient:
    BASE_URL = "https://api.revenuecat.com/v1"

    def __init__(self):
        self._api_key = settings.REVENUECAT_API_KEY

    async def get_subscriber(self, app_user_id: str) -> dict:
        if not self._api_key:
            return {"subscriber": {"entitlements": {}}}

        async with httpx.AsyncClient(
            base_url=self.BASE_URL,
            headers={
                "Authorization": f"Bearer {self._api_key}",
                "Accept": "application/json",
            },
            timeout=10.0,
        ) as client:
            response = await client.get(f"/subscribers/{app_user_id}")
            response.raise_for_status()
            return response.json()

    async def verify_subscription(self, app_user_id: str) -> bool:
        data = await self.get_subscriber(app_user_id)
        entitlements = data.get("subscriber", {}).get("entitlements", {})
        pro = entitlements.get("premium", {})
        return pro.get("expires_date") is not None
