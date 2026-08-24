"""
FastAPI 依赖注入 — 认证与数据库连接。

本模块定义了所有端点共用的 FastAPI 依赖项，通过 Depends() 注入到路由处理函数中。
依赖注入机制允许 FastAPI 在调用路由处理函数之前，自动解析并传入所需的参数，
从而解耦认证逻辑与业务逻辑，使代码更易测试、维护和复用。

模块职责：
1. 声明 HTTPBearer 安全方案实例 — 告诉 OpenAPI / Swagger 文档如何接收令牌
2. 提供 get_current_user 依赖 — 从请求头提取 Bearer Token 并验证 Firebase 身份

开发模式：
    只有 APP_ENV 为 development/test 且 ALLOW_DEV_AUTH_BYPASS 显式开启时，
    get_current_user 才返回固定的 dev-user 身份。凭据缺失不会自动关闭认证。

认证流程（正常模式）：
    客户端请求 ──► FastAPI 路由 ──► Depends(get_current_user)
                                        │
                          ┌─────────────┘
                          ▼
               HTTPBearer 从 Authorization 头提取 Token
                          │
                          ▼
               verify_firebase_token(token) 调用 Firebase Admin SDK
                          │
               ┌──────────┼──────────┐
               ▼                     ▼
          验证成功               验证失败
         返回用户 dict          抛出 HTTPException 401

使用示例（在路由文件中）：
    from app.api.deps import get_current_user

    @router.get("/me")
    async def read_my_profile(user: dict = Depends(get_current_user)):
        return {"uid": user["uid"]}
"""

# ---------------------------------------------------------------------------
# 第三方 / 标准库导入
# ---------------------------------------------------------------------------

import logging

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.config import settings
from app.core.security import verify_firebase_token

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# 模块级变量
# ---------------------------------------------------------------------------

# HTTPBearer 安全方案实例 — 全局单例，供 FastAPI OpenAPI 文档和依赖注入使用。
# FastAPI 会自动在 Swagger UI 中显示"Authorize"按钮，并附带 Bearer 认证弹窗。
# 此实例不包含任何自定义错误处理；401 响应由 get_current_user 中的 raise 统一管理。
security = HTTPBearer()


# ---------------------------------------------------------------------------
# 核心依赖函数
# ---------------------------------------------------------------------------

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    验证 Firebase ID Token 并返回当前用户信息。

    作为 FastAPI 依赖项使用，注入到需要认证的路由处理函数中。
    FastAPI 会自动从请求的 Authorization: Bearer <token> 头中提取令牌，
    开发者无需手动解析请求头。

    认证策略（按优先级判断）：
    1. 仅在安全环境显式开启 ALLOW_DEV_AUTH_BYPASS 时返回开发用户
    2. 其他情况始终调用 verify_firebase_token(token) 走完整 Firebase 验证链路

    Token 传递链路：
    ┌──────────┐     ┌──────────────┐     ┌───────────────────┐
    │ 客户端    │ ──► │ HTTPBearer   │ ──► │ get_current_user   │
    │ Bearer x  │     │ 提取 token   │     │ 验证 + 返回用户信息 │
    └──────────┘     └──────────────┘     └───────────────────┘

    Args:
        credentials (HTTPAuthorizationCredentials):
            FastAPI 通过 Depends(security) 自动注入的 HTTP 认证凭证对象。
            该对象由 HTTPBearer 从请求的 Authorization 头解析得到，包含两个属性：
            - credentials.scheme: 认证方案名称，固定为 "Bearer"
            - credentials.credentials: 实际的 JWT / Firebase ID Token 字符串

    Returns:
        dict: 包含认证用户身份的字典，至少包含以下字段：
            - uid (str): Firebase 用户唯一标识符；开发模式下固定为 "dev-user"
            - email (str): 用户电子邮箱地址；开发模式下固定为 "dev@tilezhan.app"
            正常模式下可能还包含 Firebase Token 中的其他 claims（如 name、picture 等），
            具体取决于 verify_firebase_token 的实现。

    Raises:
        HTTPException:
            - 状态码 401 (UNAUTHORIZED)：当 Token 无效、过期、已撤销，
              或 Firebase 验证流程中发生任何异常时抛出。
              开发模式不抛出异常。
            - 状态码 503 (SERVICE_UNAVAILABLE)：认证基础设施未正确初始化。
    """
    # 从 HTTPBearer 解析出的凭证对象中提取原始 Token 字符串
    token = credentials.credentials

    # 开发认证绕过必须显式开启，且永远不能在 production 中生效。
    if settings.ALLOW_DEV_AUTH_BYPASS:
        if settings.APP_ENV not in ("development", "test"):
            logger.error("Development auth bypass was enabled outside a safe environment")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication service unavailable",
            )
        return {"uid": "dev-user", "email": "dev@tilezhan.app"}

    # ── 正常模式分支 ──
    try:
        # 调用 Firebase Admin SDK 验证 Token 的真实性、时效性和签名
        # 内部会验证：
        #  - Token 签名是否与 Firebase 项目的私钥匹配
        #  - Token 是否已过期（默认 1 小时有效期）
        #  - Token 是否已被撤销（Firebase Auth 支持服务端撤销）
        #  - Token 的 aud（audience）是否匹配当前 Firebase 项目
        return await verify_firebase_token(token)
    except HTTPException:
        # 如果 verify_firebase_token 已经构造了格式化的 HTTPException
        # （例如 401 或 501），直接透传，保留其原始状态码和错误详情。
        # 不做二次包装，避免丢失底层抛出的精确错误信息。
        raise
    except Exception:
        # 捕获所有其他未预料的异常（网络故障、SDK 内部错误等），
        # 服务端记录完整异常，客户端只收到脱敏的 503。
        logger.exception("Unexpected authentication dependency failure")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        )
