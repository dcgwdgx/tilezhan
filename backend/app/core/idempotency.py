"""
幂等性守卫 — 防止数据覆盖写入。

基于时间戳的 LWW（Last-Write-Wins）冲突解决策略：
比较客户端提交的 `updated_at` 与服务端记录的更新时间，
仅当客户端数据不旧于服务端时才允许写入。

典型使用场景：
    SRS 离线同步：用户离线做题后回连，需要合并本地与服务端
    的进度。通过比较时间戳，避免用过时的本地数据覆盖服务端
    已被其他设备更新的记录。
"""


def check_idempotency(client_updated_at: int, server_updated_at: int) -> bool:
    """
    判断客户端操作是否可以执行（客户端数据不旧于服务端）。

    采用 Last-Write-Wins (LWW) 策略：
    - 若 client_updated_at >= server_updated_at → 允许写入
    - 若 client_updated_at < server_updated_at → 拒绝写入（数据过时）

    Args:
        client_updated_at: 客户端记录的更新时间戳（毫秒级 Unix 时间）。
        server_updated_at: 服务端记录的更新时间戳（毫秒级 Unix 时间）。

    Returns:
        bool: True 表示客户端数据较新或相同，可以安全写入；
              False 表示客户端数据过时，应跳过此操作。

    Note:
        此函数不做任何副作用（不抛异常、不写日志），
        调用方负责根据返回值决定后续处理逻辑。
    """
    return client_updated_at >= server_updated_at
