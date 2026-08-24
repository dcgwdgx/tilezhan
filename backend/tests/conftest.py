"""
Pytest 全局配置与共享 fixtures。

本模块为所有测试模块提供公共的异步 fixtures，包括：
- HTTP 客户端（基于 httpx.AsyncClient + ASGI 传输层）
- 认证请求头（开发环境 Bearer Token）

Fixtures 使用 pytest_asyncio 装饰器，确保在异步测试函数中正确工作。
"""

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app  # FastAPI 应用实例，通过 ASGI 传输层内联调用（无网络开销）
from app.config import settings


@pytest.fixture(autouse=True)
def explicit_test_auth_bypass(monkeypatch):
    """现有 API 测试显式使用测试认证，不再依赖 Firebase 配置缺失自动放行。"""
    monkeypatch.setattr(settings, "APP_ENV", "test")
    monkeypatch.setattr(settings, "ALLOW_DEV_AUTH_BYPASS", True)


@pytest_asyncio.fixture
async def auth_headers():
    """
    提供开发环境下的认证请求头字典。

    返回一个包含 Authorization 头的字典，所有需要鉴权的测试接口可直接
    解包传入 client.get() / client.post() 的 headers 参数。

    Returns:
        dict: {"Authorization": "Bearer dev-token"} 形式的认证头。
    """
    return {"Authorization": "Bearer dev-token"}


@pytest_asyncio.fixture
async def client():
    """
    提供基于 ASGI 传输层的异步 HTTP 测试客户端。

    使用 httpx.AsyncClient + ASGITransport 绑定 FastAPI app，
    所有请求直接在内存中通过 ASGI 协议传递，无需启动真实服务器或监听端口。
    base_url="http://test" 确保测试请求的 URL 具有合法的 scheme/host 前缀。

    用法:
        async def test_something(client):
            response = await client.get("/api/resource")
            assert response.status_code == 200

    Yields:
        httpx.AsyncClient: 一个已连接到 ASGI app 的异步 HTTP 客户端。
            测试函数使用完毕后自动关闭（async context manager 的 __aexit__ 逻辑）。
    """
    async with AsyncClient(
        transport=ASGITransport(app=app),  # 将请求路由到 FastAPI app，绕过网络栈
        base_url="http://test",            # 占位 base_url，满足 httpx 对完整 URL 的要求
    ) as ac:
        yield ac  # 将客户端实例注入测试函数
