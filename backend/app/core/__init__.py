"""
Core 层包 — TileZhan 后端核心基础设施。

本包包含：
- security：Firebase 身份认证令牌验证
- firebase：Firebase Admin SDK 懒加载初始化
- exceptions：全局异常类与异常处理器
- revenuecat：RevenueCat REST API 客户端
- ntp_guard：NTP 时间防作弊校验
- idempotency：幂等性守卫（防止重复写入）
- subscription_store：订阅状态内存存储 + 分析数据
"""
