"""
全局异常类与异常处理器 — 统一的 HTTP 状态码映射。

本模块定义了 TileZhan 后端的异常层次结构：
- AppError：基础应用异常（可自由配置 HTTP 状态码）
- StaleDataError：客户端数据过时（409 Conflict）
- RateLimitExceeded：请求频率超限（429 Too Many Requests）
- InsufficientStamina：体力不足（400 Bad Request）
- TimestampTampered：客户端时间戳异常（400 Bad Request）

并提供 FastAPI 全局异常处理器 `app_error_handler`，在 FastAPI 的
exception_handlers 字典中注册后，可将所有 AppError 子类统一转换为
{"error": ..., "code": ...} 格式的 JSON 错误响应，前端只需解析这一种结构。

使用方式（在 main.py 或路由初始化处注册）：
    from app.core.exceptions import AppError, app_error_handler
    app.add_exception_handler(AppError, app_error_handler)
"""

from fastapi import Request  # FastAPI 请求对象，异常处理器中用于获取请求上下文（当前未消费，保留扩展点）
from fastapi.responses import JSONResponse  # JSON 格式的 HTTP 响应类，用于构造统一错误体


class AppError(Exception):
    """
    应用层基础异常 — 所有业务异常的抽象基类。

    继承自 Python 内置 Exception，新增 `status_code` 与 `message` 两个字段，
    使每个异常实例自带 HTTP 状态码和面向客户端的错误描述。

    关键设计意图：
    - 全局异常处理器仅捕获 AppError 及其子类，从而将"预期的业务错误"与
      "未预期的运行时错误"区分开。
    - 子类通常在 __init__ 中写死 message 和 status_code，调用方只需 `raise` 即可。

    Attributes:
        message (str): 面向客户端的错误描述信息，会直接出现在 JSON 响应的 error 字段中。
        status_code (int): 对应的 HTTP 状态码，默认 400（Bad Request）。
    """

    def __init__(self, message: str, status_code: int = 400):
        """
        初始化应用异常实例。

        Args:
            message (str): 人类可读的错误描述，将作为 API 响应的 error 字段返回给客户端。
            status_code (int, 可选): HTTP 状态码，默认为 400。子类可通过 super().__init__()
                传入特定的状态码（如 409、429）。
        """
        self.message = message  # 错误消息文本，由异常处理器写入 JSON 响应的 error 字段
        self.status_code = status_code  # HTTP 状态码，由异常处理器写入响应的 status_code


class StaleDataError(AppError):
    """
    数据过期异常 — 禁止用旧数据覆盖服务端较新的数据（乐观锁冲突）。

    触发场景：
    - 前端提交的数据版本号（或 updated_at 时间戳）早于数据库中的当前记录，
      表明在用户编辑期间有其他客户端/进程修改了同一数据。
    - 服务端不允许"后写覆盖先写"，因此拒绝本次提交。

    客户端收到此错误后的正确行为：
    1. 从服务端重新拉取最新数据；
    2. 合并/重新应用用户的修改（或提示用户刷新）；
    3. 再次提交。

    HTTP 状态码: 409 Conflict
    """

    def __init__(self):
        """
        初始化数据过期异常。

        Args:
            无参数 — message 与 status_code 已内置。
        """
        # 调用父类构造器，传入固定的 409 Conflict 状态码与预定义消息
        super().__init__("Data is stale. Refresh and retry.", 409)


class RateLimitExceeded(AppError):
    """
    请求频率限制异常 — 客户端在时间窗口内发送了过多请求。

    触发场景：
    - 用户在短时间内（如 1 分钟）向同一接口发送了超过允许上限的请求数。
    - 通常由 Redis/内存限流中间件触发，抛出此异常以中断处理链。

    客户端行为建议：
    - 读取响应中的 Retry-After 头（如有）并在指定秒数后重试；
    - 或实现指数退避（exponential backoff）策略。

    HTTP 状态码: 429 Too Many Requests
    """

    def __init__(self):
        """
        初始化限流异常。

        Args:
            无参数 — message 与 status_code 已内置。
        """
        # 调用父类构造器，传入固定的 429 Too Many Requests 状态码与预定义消息
        super().__init__("Too many requests", 429)


class InsufficientStamina(AppError):
    """
    体力不足异常 — 用户当前心数不足以执行指定操作。

    触发场景：
    - 用户尝试消耗体力（如翻开牌、进行对战）但当前剩余心数为 0。
    - 前端应优先通过本地状态判断避免无效请求，此异常作为服务端兜底校验。

    设计说明：
    - 与冷却时间（cooldown）不同，此异常仅关心"当前心数是否足够"；
      时间恢复逻辑由定时任务（如 Celery）或 Redis 过期键驱动。

    HTTP 状态码: 400 Bad Request
    """

    def __init__(self):
        """
        初始化体力不足异常。

        Args:
            无参数 — message 与 status_code 已内置。
        """
        # 调用父类构造器，传入固定的 400 Bad Request 状态码与预定义消息
        super().__init__("No hearts remaining", 400)


class TimestampTampered(AppError):
    """
    客户端时间戳异常 — 服务端防作弊检测触发。

    触发场景：
    - 用户提交操作请求时附带了 client_timestamp 字段，它指示用户声称的操作发生时刻。
    - 服务端比对 client_timestamp 与自己的系统时钟，若偏差超过配置的容忍阈值
      （如 30 秒），则判定用户可能修改了手机时钟以绕过体力冷却等时间限制。

    安全含义：
    - 此机制是体力/冷却系统的一道重要防线，防止客户端时钟欺骗。
    - 业务逻辑中的重要操作（消耗体力、领取奖励等）应在处理前校验时间戳。

    HTTP 状态码: 400 Bad Request
    """

    def __init__(self):
        """
        初始化时间戳篡改异常。

        Args:
            无参数 — message 与 status_code 已内置。
        """
        # 调用父类构造器，传入固定的 400 Bad Request 状态码与预定义消息
        super().__init__("Client timestamp deviates from server time", 400)


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    """
    FastAPI 全局异常处理器 — 将 AppError 子类转换为统一 JSON 错误响应。

    在 FastAPI 应用中注册后（app.add_exception_handler(AppError, app_error_handler)），
    所有未被路由函数内 try/except 吞噬的 AppError 及其子类都将被此协程捕获。

    响应格式：
        HTTP 状态码: exc.status_code
        Content-Type: application/json
        Body: {"error": "<exc.message>", "code": "<异常类名>"}

    其中 code 字段使用 type(exc).__name__ 自动获取类名（如 "StaleDataError"），
    方便前端根据 code 做差异化处理而不依赖 message 字符串匹配。

    Args:
        request (Request): FastAPI 请求对象，提供请求方法、URL、客户端 IP 等上下文。
            当前实现未直接消费 request，保留参数签名供未来扩展（如日志记录、链路追踪）。
        exc (AppError): 被捕获的应用异常实例，其 message 和 status_code 属性
            将被写入 HTTP 响应。

    Returns:
        JSONResponse: FastAPI 兼容的 JSON 响应对象，包含：
            - status_code: 从 exc.status_code 继承的 HTTP 状态码
            - content: {"error": exc.message, "code": type(exc).__name__}
    """
    return JSONResponse(
        status_code=exc.status_code,  # 从异常实例读取 HTTP 状态码（400/409/429 等）
        content={
            "error": exc.message,  # 面向客户端的错误描述文本
            "code": type(exc).__name__,  # 异常类名（如 "StaleDataError"），便于前端按类型分流处理
        },
    )
