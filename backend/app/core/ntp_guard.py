"""
NTP 时间防作弊校验 — 服务端时间戳验证。

通过比较客户端提交的时间戳与服务端当前时间，检测用户是否
通过修改手机时钟来绕过体力冷却等时间限制。

最大允许偏差：300 秒（5 分钟）。
若偏差超过此值，抛出 TimestampTampered 异常。

安全原理：
    即使客户端修改了本地时钟，NTP 同步后的偏差仍能被服务端
    检测到，从而拒绝伪造的时间戳请求。
"""

from datetime import datetime, timedelta, timezone


MAX_DEVIATION_SECONDS = 300  # 最大允许偏差：5 分钟


def validate_client_timestamp(client_timestamp_ms: int) -> None:
    """
    验证客户端时间戳是否在允许偏差范围内。

    将客户端毫秒级时间戳转换为 UTC 时间，与服务端当前 UTC 时间
    进行比对。若偏差超过 MAX_DEVIATION_SECONDS，抛出异常。

    Args:
        client_timestamp_ms: 客户端提交的 Unix 时间戳（毫秒）。

    Raises:
        TimestampTampered: 客户端时间与服务端时间偏差超过 5 分钟。

    Note:
        此函数应在所有涉及体力消耗、冷却计时等时间敏感的
        端点中调用，作为防作弊的第一道防线。
    """
    from app.core.exceptions import TimestampTampered

    server_now = datetime.now(timezone.utc)
    # 将毫秒时间戳转换为 UTC datetime 对象
    client_time = datetime.fromtimestamp(client_timestamp_ms / 1000, tz=timezone.utc)
    deviation = abs((server_now - client_time).total_seconds())

    if deviation > MAX_DEVIATION_SECONDS:
        raise TimestampTampered()
