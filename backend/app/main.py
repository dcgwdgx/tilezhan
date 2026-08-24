"""
TileZhan — FastAPI 应用入口模块。

本模块负责:
1. 创建并配置 FastAPI 应用实例。
2. 注册生命周期事件（启动/关闭时执行资源初始化和清理）。
3. 配置 CORS 中间件，控制跨域访问策略。
4. 挂载 API v1 路由，统一以 /api/v1 为前缀。
5. 暴露 /health 健康检查端点，供负载均衡和监控系统使用。

使用方式:
    uvicorn app.main:app --host 0.0.0.0 --port 8000
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings, validate_runtime_settings
from app.core.firebase import initialize_firebase
from app.api.v1.router import api_router  # v1 版本的全部路由聚合器


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    FastAPI 应用生命周期管理器。

    在应用启动时（yield 之前）执行初始化逻辑（如数据库连接池预热、Redis 连接建立等）。
    在应用关闭时（yield 之后）执行清理逻辑（如关闭连接、刷新缓冲区等）。

    Args:
        app: 当前 FastAPI 应用实例，可用于访问 app.state 存放全局资源。

    Yields:
        None: 控制权交给 FastAPI，应用在 yield 期间正常运行。
    """
    # 生产配置必须在接收请求前完成校验；Firebase 也必须先于认证请求初始化。
    validate_runtime_settings(settings)
    app.state.firebase_app = initialize_firebase(
        required=settings.APP_ENV == "production"
    )
    yield
    # ========== 关闭阶段 ==========
    # 可在此处执行: 关闭数据库连接池、断开 Redis、清理临时文件等


# FastAPI 应用实例 —— 整个服务端入口。
# - title: API 文档标题，来自配置中的 APP_NAME。
# - version: 当前 API 版本号，用于 OpenAPI schema 中展示。
# - lifespan: 启动/关闭时的资源管理回调。
app = FastAPI(title=settings.APP_NAME, version=settings.APP_VERSION, lifespan=lifespan)

# ---------- CORS 跨域中间件 ----------
# 允许 ALLOWED_ORIGINS 中指定的前端来源进行跨域请求。
# - allow_credentials=True: 允许携带 Cookie / Authorization 头。
# - allow_methods=["*"]: 允许所有 HTTP 方法（GET, POST, PUT, DELETE, PATCH, OPTIONS 等）。
# - allow_headers=["*"]: 允许所有请求头。
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- 路由注册 ----------
# 将 v1 版本的所有子路由挂载到 /api/v1 前缀下。
# 例如: /api/v1/mahjong, /api/v1/users 等。
app.include_router(api_router, prefix="/api/v1")

# ==================== 健康检查 ====================


@app.get("/health")
async def health():
    """
    健康检查端点 —— GET /health。

    供 Kubernetes 探针、负载均衡器和外部监控服务调用，
    用于判断应用实例是否处于存活状态。

    Returns:
        dict: 包含 status (固定 "ok") 和当前 API 版本号的 JSON 响应。
    """
    return {"status": "ok", "version": settings.APP_VERSION}
