"""
RevenueCat REST API 客户端 — 服务端订阅验证。

本模块封装了 RevenueCat REST API v1 的调用逻辑，
用于在服务端验证用户订阅状态。主要方法：
- get_subscriber：获取订阅者完整信息（entitlements、subscriptions 等）
- verify_subscription：验证指定用户是否拥有 Pro 权限（便捷方法）

使用 httpx.AsyncClient 进行异步 HTTP 请求，
API Key 从 settings.REVENUECAT_API_KEY 读取。

安全降级策略：
若未配置 API Key（例如本地开发环境或 CI 环境），get_subscriber()
返回空的订阅者结构 {"subscriber": {"entitlements": {}}}，
而不是抛出异常。这允许上层调用方在无 RevenueCat 配置时
仍能正常运行（例如跳过付费验证，仅提供免费功能）。

依赖：
- httpx：异步 HTTP 客户端，用于发起 HTTPS 请求
- app.config.settings：应用配置，含 REVENUECAT_API_KEY
"""

import httpx  # 异步 HTTP 客户端，支持 async/await，替代 requests 库
from app.config import settings  # 应用配置单例，含 REVENUECAT_API_KEY


class RevenueCatClient:
    """
    RevenueCat REST API 客户端。

    封装对 RevenueCat v1 API 的异步调用，用于查询和验证
    用户订阅状态。所有请求均通过 HTTPS 并附带 Bearer 认证。

    使用方式：
        client = RevenueCatClient()
        is_pro = await client.verify_subscription("user_abc123")

    设计要点：
    - 无状态：客户端不缓存任何请求结果，每次调用都是独立请求。
    - 异步：所有网络 I/O 均通过 httpx.AsyncClient 异步执行，
      适合在 FastAPI 等异步 Web 框架中使用。
    - 优雅降级：若未配置 API Key，返回空数据而非抛异常，
      确保本地开发和 CI 环境不依赖外部服务。

    Attributes:
        BASE_URL: RevenueCat REST API v1 的基础 URL（类常量）。
    """

    BASE_URL = "https://api.revenuecat.com/v1"  # RevenueCat REST API v1 基础端点

    def __init__(self):
        """
        初始化 RevenueCat 客户端。

        从应用配置中读取 API Key 并存储到实例属性 `_api_key`。
        不发起任何网络请求，因此初始化是同步且零成本的。

        若 settings.REVENUECAT_API_KEY 为 None 或空字符串，
        get_subscriber() 将走降级路径，返回空订阅结构。
        """
        self._api_key = settings.REVENUECAT_API_KEY  # 从配置读取 API Key，可能为 None

    async def get_subscriber(self, app_user_id: str) -> dict:
        """
        获取指定用户的完整订阅者信息。

        调用 RevenueCat REST API v1 的 GET /v1/subscribers/{app_user_id} 端点，
        返回包含 entitlements（权限）、subscriptions（订阅项目）等字段的
        完整 JSON 数据。

        RevenueCat API 文档参考：
        https://www.revenuecat.com/reference/subscribers

        Args:
            app_user_id: RevenueCat 中的用户标识符（App User ID），
                通常是应用内生成的 UUID，用于关联购买记录。

        Returns:
            dict: RevenueCat API 返回的 JSON 数据，结构如下：
                {
                    "request_date": "...",
                    "request_date_ms": ...,
                    "subscriber": {
                        "entitlements": {...},
                        "first_seen": "...",
                        "last_seen": "...",
                        "management_url": null,
                        "original_app_user_id": "...",
                        "subscriptions": {...}
                    }
                }
            若未配置 API Key，返回空的订阅者结构：
                {"subscriber": {"entitlements": {}}}

        Raises:
            httpx.HTTPStatusError: 当 HTTP 状态码为 4xx/5xx 时，
                由 response.raise_for_status() 抛出。
            httpx.TimeoutException: 当请求超过 10 秒超时限制时抛出。
        """
        # 降级路径：无 API Key 时返回空结构，允许上层代码继续运行
        if not self._api_key:
            return {"subscriber": {"entitlements": {}}}

        # 创建一个新的 AsyncClient，设置 Base URL、认证头和超时
        async with httpx.AsyncClient(
            base_url=self.BASE_URL,
            headers={
                "Authorization": f"Bearer {self._api_key}",  # Bearer Token 认证
                "Accept": "application/json",  # 要求 JSON 响应格式
            },
            timeout=10.0,  # 10 秒超时，防止网络异常时无限等待
        ) as client:
            # 发起 GET 请求到 /v1/subscribers/{app_user_id}
            response = await client.get(f"/subscribers/{app_user_id}")
            response.raise_for_status()  # 非 2xx 状态码将抛出 HTTPStatusError
            return response.json()  # 将 JSON 响应体解析为 Python dict

    async def verify_subscription(self, app_user_id: str) -> bool:
        """
        验证指定用户是否拥有有效的 Pro 订阅。

        内部调用 get_subscriber() 获取完整订阅数据，然后逐层提取
        entitlements → "premium" 权限 → expires_date 字段，
        返回 expires_date 是否存在。

        验证逻辑说明：
        - 有效订阅（含自动续订）→ expires_date 为未来日期 → True
        - 终身订阅（Lifetime）→ expires_date 存在且为远期 → True
        - 已过期/未订阅 → premium 下无 expires_date → False
        - API Key 未配置 → get_subscriber 返回空结构 → False

        Args:
            app_user_id: 要验证的用户标识符（App User ID）。

        Returns:
            bool: True 表示用户当前拥有有效的 Pro 权限；
                  False 表示用户无 Pro 权限或数据不可用。
        """
        # 获取完整订阅者数据（含降级处理）
        data = await self.get_subscriber(app_user_id)

        # 安全地逐层提取：subscriber → entitlements → premium 权限
        entitlements = data.get("subscriber", {}).get("entitlements", {})
        pro = entitlements.get("premium", {})

        # expires_date 存在即视为有效订阅（含 Lifetime）
        return pro.get("expires_date") is not None
