"""
API v1 子包 — 包含了 v1 版本下的所有端点模块。

各模块功能：
- router：聚合所有子路由到统一的 APIRouter
- puzzles：每日任务、闪卡、何切问题
- mahjong：向听数/进张数计算引擎
- srs：间隔重复系统复习端点
- user：用户资料、体力系统
- products：IAP 产品定义
- products_data：RevenueCat 产品配置（单一数据源）
- subscription：订阅验证与 RevenueCat webhook
- analytics：仪表盘与事件追踪
- leaderboard：全局 ELO 排行榜
"""
