"""
RevenueCat REST API 客户端 — 服务端订阅验证。

本模块封装了 RevenueCat REST API v1 的调用逻辑，
用于在服务端验证用户订阅状态。主要方法：
- get_subscriber：获取订阅者完整信息
- verify_subscription：验证指定用户是否拥有 Pro 权限

使用 httpx.AsyncClient 进行异步 HTTP 请求，
API Key 从 settings.REVENUECAT_API_KEY 读取。
若未配置 API Key，返回空的订阅信息以允许优雅降级。
"""

import httpx
from app.config import settings


class RevenueCatClient:
    """
    RevenueCat REST API 客户端。

    封装对 RevenueCat v1 API 的异步调用，用于查询和验证
    用户订阅状态。所有请求均通过 HTTPS 并附带 Bearer 认证。

    Attributes:
        BASE_URL: RevenueCat API 基础 URL。
    """

    BASE_URL = "https://api.revenuecat.com/v1"

    def __init__(self):
        """
        初始化 RevenueCat 客户端。

        从应用配置中读取 API Key，不发起网络请求。
        """
        self._api_key = settings.REVENUECAT_API_KEY

    async def get_subscriber(self, app_user_id: str) -> dict:
        """
        获取指定用户的完整订阅者信息。

        调用 GET /v1/subscribers/{app_user_id} 端点，
        返回包含 entitlements、subscriptions 等字段的完整数据。

        Args:
            app_user_id: RevenueCat 中的用户标识符（App User ID）。

        Returns:
            dict: RevenueCat API 返回的 JSON 数据；
            若未配置 API Key，返回空的订阅者结构。
        """
        if not self._api_key:
            return {"subscriber": {"entitlements": {}}}

        async with httpx.AsyncClient(
            base_url=self.BASE_URL,
            headers={
                "Authorization": f"Bearer {self._api_key}",
                "Accept": "application/json",
            },
            timeout=10.0,  # 10 秒超时，避免长时间阻塞
        ) as client:
            response = await client.get(f"/subscribers/{app_user_id}")
            response.raise_for_status()
            return response.json()

    async def verify_subscription(self, app_user_id: str) -> bool:
        """
        验证指定用户是否拥有有效的 Pro 订阅。

        内部调用 get_subscriber()，然后检查 entitlements 中
        "premium" 权限的 expires_date 是否存在。
        存在即表示订阅有效（包括 Lifetime）。

        Args:
            app_user_id: 要验证的用户标识符。

        Returns:
            bool: True 表示拥有有效的 Pro 权限，False 反之。
        """
        data = await self.get_subscriber(app_user_id)
        entitlements = data.get("subscriber", {}).get("entitlements", {})
        pro = entitlements.get("premium", {})
        return pro.get("expires_date") is not None
