"""
全局异常类与异常处理器 — 统一的 HTTP 状态码映射。

本模块定义了 TileZhan 后端的异常层次结构：
- AppError：基础应用异常（可配置 HTTP 状态码）
- StaleDataError：客户端数据过时（409 Conflict）
- RateLimitExceeded：请求频率超限（429 Too Many Requests）
- InsufficientStamina：体力不足（400 Bad Request）
- TimestampTampered：客户端时间戳异常（400 Bad Request）

并提供 FastAPI 异常处理器 `app_error_handler`，将所有 AppError 子类
转换为统一的 JSON 错误响应格式。
"""

from fastapi import Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    """
    应用层基础异常。

    所有业务异常应继承此类，以便被全局异常处理器统一捕获。

    Attributes:
        message: 面向客户端的错误描述信息。
        status_code: HTTP 状态码，默认 400。
    """

    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code


class StaleDataError(AppError):
    """
    数据过期异常 — 禁止覆盖服务端较新的数据。

    当客户端提交的数据版本比服务端记录更旧时抛出。
    客户端应刷新本地数据后重试。

    HTTP 状态码: 409 Conflict
    """

    def __init__(self):
        super().__init__("Data is stale. Refresh and retry.", 409)


class RateLimitExceeded(AppError):
    """
    请求频率限制异常。

    当客户端请求过于频繁时抛出。

    HTTP 状态码: 429 Too Many Requests
    """

    def __init__(self):
        super().__init__("Too many requests", 429)


class InsufficientStamina(AppError):
    """
    体力不足异常。

    当用户尝试消耗体力但当前心数为 0 时抛出。

    HTTP 状态码: 400 Bad Request
    """

    def __init__(self):
        super().__init__("No hearts remaining", 400)


class TimestampTampered(AppError):
    """
    客户端时间戳异常 — 防作弊检测触发。

    当客户端提交的时间戳与服务端时间偏差超过允许范围时抛出，
    用于防止通过修改手机时钟绕过体力冷却。

    HTTP 状态码: 400 Bad Request
    """

    def __init__(self):
        super().__init__("Client timestamp deviates from server time", 400)


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    """
    FastAPI 全局异常处理器。

    将所有 AppError 及其子类转换为统一的 JSON 错误响应，
    格式为 {"error": <错误消息>, "code": <异常类名>}。

    Args:
        request: FastAPI 请求对象。
        exc: 捕获到的 AppError 异常实例。

    Returns:
        JSONResponse: 包含错误码和错误消息的 JSON 响应。
    """
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.message, "code": type(exc).__name__},
    )
