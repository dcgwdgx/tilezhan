"""
API v1 路由聚合器 — 将各子模块路由统一挂载到 v1 路径下。

本模块创建一个顶层的 APIRouter 实例，
并通过 include_router() 聚合以下子路由：
- user：用户资料与体力系统
- puzzles：每日任务、闪卡、何切问题
- mahjong：向听数/进张数计算引擎
- srs：间隔重复系统
- subscription：订阅验证与 RevenueCat webhook
- products：IAP 产品定义
- analytics：仪表盘与事件追踪
- leaderboard：全局排行榜

所有子路由通过各自的 prefix 和 tags 进行命名空间隔离。
"""

from fastapi import APIRouter

from app.api.v1 import puzzles, mahjong, srs, user, subscription, products, analytics, leaderboard

# 创建 v1 顶层路由，各子模块自行携带 prefix 和 tags
api_router = APIRouter()
api_router.include_router(user.router)
api_router.include_router(puzzles.router)
api_router.include_router(mahjong.router)
api_router.include_router(srs.router)
api_router.include_router(subscription.router)
api_router.include_router(products.router)
api_router.include_router(analytics.router)
api_router.include_router(leaderboard.router)
