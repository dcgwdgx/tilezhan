"""
RevenueCat 产品定义 — 单一数据源（Single Source of Truth）。

本模块是 TileZhan 所有 IAP 商品定义的权威数据源，
其他模块（products API、subscription store 等）均从此处读取。

当前商品：
- tilezhan_premium_monthly: Pro 月费订阅 $4.99/月
- tilezhan_premium_yearly: Pro 年费订阅 $29.99/年（比月费节省 50%）

权限映射：
    所有 Pro 订阅均映射到 "premium" 权限等级。
    Lifetime 买断（待添加）将映射到 "lifetime" 等级。

注意：
    此处的价格和描述仅用于客户端展示；
    实际交易由 RevenueCat SDK 在客户端和 App Store / Google Play 之间完成。
    服务端仅负责订阅状态验证和权限下发。
"""

PRODUCTS = {
    "tilezhan_premium_monthly": {
        "type": "subscription",
        "price": 4.99,
        "currency": "USD",
        "period": "P1M",  # ISO 8601 duration: 1 month
        "title": "TileZhan Pro Monthly",
        "description": "Unlimited hearts, all mnemonic illustrations, advanced puzzles",
    },
    "tilezhan_premium_yearly": {
        "type": "subscription",
        "price": 29.99,
        "currency": "USD",
        "period": "P1Y",  # ISO 8601 duration: 1 year
        "title": "TileZhan Pro Yearly",
        "description": "50% off vs monthly — best value for dedicated learners",
    },
}

# 商品 ID → 权限等级映射
# 用于 RevenueCat webhook 处理时确定用户应获得的权限
ENTITLEMENT_MAP = {
    "tilezhan_premium_monthly": "premium",
    "tilezhan_premium_yearly": "premium",
}
