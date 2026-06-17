"""
NTP 时间防作弊校验 — 服务端时间戳验证。
==================================================

通过比较客户端提交的时间戳与服务端当前时间，检测用户是否
通过修改手机时钟来绕过体力冷却等时间限制。

最大允许偏差：300 秒（5 分钟）。
若偏差超过此值，抛出 TimestampTampered 异常。

安全原理：
    即使客户端修改了本地时钟，NTP 同步后的偏差仍能被服务端
    检测到，从而拒绝伪造的时间戳请求。

使用方式：
    在所有涉及体力消耗、冷却计时、签到奖励等时间敏感接口中，
    调用 validate_client_timestamp() 作为请求校验的第一步。

    示例::

        from app.core.ntp_guard import validate_client_timestamp

        @router.post("/stamina/consume")
        async def consume_stamina(request: ConsumeRequest):
            validate_client_timestamp(request.timestamp_ms)
            # ... 后续业务逻辑

模块依赖：
    - app.core.exceptions.TimestampTampered: 时间篡改专用异常类
"""

# Python 标准库：日期时间处理与时区支持
from datetime import datetime, timedelta, timezone


# 最大允许偏差（秒）：客户端时间戳与服务端时间之间的最大容忍差值
# 设置 300 秒（5 分钟）作为合理余量，既能覆盖正常的网络延迟和时钟漂移，
# 又能有效防止用户通过修改系统时钟绕过冷却等时间限制。
MAX_DEVIATION_SECONDS = 300  # 最大允许偏差：5 分钟


def validate_client_timestamp(client_timestamp_ms: int) -> None:
    """
    验证客户端时间戳是否在允许偏差范围内（NTP 防作弊核心函数）。

    将客户端提交的毫秒级 Unix 时间戳转换为 UTC datetime 对象，
    与服务端当前 UTC 时间进行绝对值比对。若偏差超过阈值
    MAX_DEVIATION_SECONDS（默认 300 秒），则判定为时间被篡改，
    抛出 TimestampTampered 异常以拒绝该请求。

    参数:
        client_timestamp_ms (int): 客户端提交的 Unix 时间戳，
                                   以毫秒为单位（JavaScript 风格）。
                                   通常由前端通过 ``Date.now()`` 获取
                                   并通过 API 请求体传入。

    返回:
        None: 验证通过时静默返回，不产生任何副作用。

    引发:
        TimestampTampered: 当 ``|server_time - client_time| > 300s`` 时抛出。
                           该异常继承自 HTTPException，HTTP 状态码为 403，
                           前端收到后应提示用户关闭设备自动时间同步功能。

    安全原理:
        1. 服务端获取可信 UTC 时间（不受客户端控制）。
        2. 将客户端时间戳反序列化为 UTC datetime。
        3. 计算两者差值的绝对值即为「时钟偏差」。
        4. 若偏差超阈值，说明客户端本地时钟被人为修改。

        该方案不需要客户端做 NTP 同步，只需客户端在请求中携带
        ``Date.now()`` 即可实现低成本、高可靠的时间防作弊。

    性能考量:
        - 纯 CPU 计算，无 I/O、无数据库查询，耗时 < 1ms。
        - 可在高并发场景下放心放置于接口入口处。

    调用约定:
        此函数应在所有涉及以下场景的端点中最先调用：
        - 体力消耗与自然恢复
        - 技能冷却计时
        - 每日签到 / 每日任务刷新
        - 限时活动 / 赛季结算
        - 任何依赖「真实时间流逝」的业务逻辑
    """
    # 延迟导入异常类（避免模块级循环依赖，同时保持异常定义集中管理）
    from app.core.exceptions import TimestampTampered

    # 获取服务端当前 UTC 时间作为可信基准
    server_now = datetime.now(timezone.utc)

    # 将客户端毫秒时间戳（除以 1000 转为秒）反序列化为 UTC datetime 对象
    client_time = datetime.fromtimestamp(client_timestamp_ms / 1000, tz=timezone.utc)

    # 计算服务端与客户端时间差的绝对值（秒）
    # total_seconds() 将 timedelta 转为浮点秒数，abs() 取绝对值
    deviation = abs((server_now - client_time).total_seconds())

    # 偏差超过阈值 → 判定为时钟篡改，拒绝请求
    if deviation > MAX_DEVIATION_SECONDS:
        raise TimestampTampered()
