"""Mahjong Backend — 配置模块

使用 pydantic-settings 从环境变量和 .env 文件加载运行时配置。
所有配置项均有默认值，支持开发环境零配置启动。

模块入口:
    settings (Settings): 全局单例配置实例，各模块导入此对象读取配置。

环境变量:
    所有配置项通过大写同名环境变量覆盖。示例:
        export FIREBASE_PROJECT_ID=my-project
        export ALLOWED_ORIGINS='["https://my.app"]'
"""

from typing import Literal

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """应用全局配置，基于 pydantic-settings 自动加载环境变量与 .env 文件。

    属性分类:
        - 应用元信息 (APP_NAME, APP_VERSION, DEBUG)
        - Firebase / Firestore 凭证
        - RevenueCat 支付集成
        - Redis 连接
        - 安全与限流 (RATE_LIMIT, ALLOWED_ORIGINS)
        - 业务配置 (MAHJONG_RULE_SET)

    注意:
        敏感凭证（如 FIREBASE_PRIVATE_KEY）默认留空，
        生产环境必须通过环境变量或 .env 注入。
    """

    # ── 应用元信息 ──────────────────────────────────────────────
    APP_NAME: str = "TileZhan API"
    # 应用显示名称，用于 OpenAPI 文档标题和日志标识

    APP_VERSION: str = "1.0.0"
    # 应用版本号，语义化版本 (SemVer)，显示于 /health 和 docs

    APP_ENV: Literal["development", "test", "production"] = "development"
    # 明确的运行环境。安全相关行为不得再通过凭据是否缺失来推断。

    DEBUG: bool = False
    # 调试模式开关：True 时启用详细错误页、热重载；生产环境必须为 False

    ALLOW_DEV_AUTH_BYPASS: bool = False
    # 仅允许在 development/test 中显式开启；生产环境永远禁止绕过 Firebase 认证。

    # ── Firebase / Firestore ─────────────────────────────────────
    FIREBASE_PROJECT_ID: str = ""
    # Firebase 项目 ID，用于初始化 firebase-admin SDK

    FIREBASE_PRIVATE_KEY: str = ""
    # Firebase 服务账号私钥 (PEM 格式)，用于签发自定义 token 和验证 JWT
    # 注意：换行符需用 \\n 转义，或通过环境变量直接注入多行值

    FIREBASE_CLIENT_EMAIL: str = ""
    # Firebase 服务账号邮箱 (xxx@xxx.iam.gserviceaccount.com)

    FIRESTORE_DATABASE: str = "(default)"
    # Firestore 数据库 ID："(default)" 表示默认数据库，也可指定命名数据库

    # ── RevenueCat 支付集成 ──────────────────────────────────────
    REVENUECAT_API_KEY: str = ""
    # RevenueCat REST API v2 Key，用于服务端校验订阅状态和获取权益信息

    REVENUECAT_WEBHOOK_SECRET: str = ""
    # RevenueCat Webhook 签名密钥，用于验证 webhook 请求来源真实性

    # ── Redis ────────────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/0"
    # Redis 连接 URL，格式: redis://[:password@]host:port[/db]
    # 支持 Redis、Valkey、KeyDB 等兼容服务

    # ── 安全与限流 ──────────────────────────────────────────────
    RATE_LIMIT_PER_MINUTE: int = 100
    # 全局每分钟请求上限，超出后返回 429 Too Many Requests

    ALLOWED_ORIGINS: list[str] = ["https://tilezhan.app"]
    # CORS 允许的来源列表，用于 CORSMiddleware 白名单校验
    # 示例: ["https://tilezhan.app", "http://localhost:5173"]

    # ── 业务配置 ─────────────────────────────────────────────────
    MAHJONG_RULE_SET: str = "riichi"
    # 麻将规则集标识符：可选 "riichi" (立直) / "mcr" (国标) / "hk" (香港)
    # 该值控制牌型计算引擎加载的规则模块

    # ── pydantic-settings 元配置 ─────────────────────────────────
    model_config = {"env_file": ".env"}
    # 指定从项目根目录的 .env 文件加载环境变量
    # 环境变量优先级高于 .env 文件（默认行为）


# ── 全局单例 ─────────────────────────────────────────────────────────
PRODUCTION_REQUIRED_SETTINGS = (
    "FIREBASE_PROJECT_ID",
    "FIREBASE_PRIVATE_KEY",
    "FIREBASE_CLIENT_EMAIL",
    "REVENUECAT_WEBHOOK_SECRET",
)


def validate_runtime_settings(runtime_settings: Settings) -> None:
    """验证启动时配置；生产环境配置不完整时拒绝启动。"""
    if runtime_settings.APP_ENV != "production":
        return

    invalid_flags = []
    if runtime_settings.DEBUG:
        invalid_flags.append("DEBUG must be false")
    if runtime_settings.ALLOW_DEV_AUTH_BYPASS:
        invalid_flags.append("ALLOW_DEV_AUTH_BYPASS must be false")

    missing = [
        name
        for name in PRODUCTION_REQUIRED_SETTINGS
        if not str(getattr(runtime_settings, name, "")).strip()
    ]

    problems = []
    if missing:
        problems.append(f"missing required settings: {', '.join(missing)}")
    problems.extend(invalid_flags)
    if problems:
        raise RuntimeError(
            "Invalid production configuration: " + "; ".join(problems)
        )


settings = Settings()
# 模块级单例：整个应用通过 `from app.config import settings` 获取同一实例
# 首次导入时自动完成环境变量和 .env 文件的加载与校验
