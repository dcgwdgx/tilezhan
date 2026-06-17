"""
FastAPI 依赖注入 — 认证与数据库连接。

本模块定义了所有端点共用的 FastAPI 依赖项，
通过 Depends() 注入到路由处理函数中。

主要依赖：
- security: HTTPBearer 安全方案实例
- get_current_user: 从请求头提取 Bearer Token 并验证 Firebase 身份

开发模式：
    当 settings.DEBUG 为 True 或 FIREBASE_PROJECT_ID 未配置时，
    get_current_user 返回固定的 dev-user 身份，无需真实 Firebase 令牌。
    这使得开发/测试环境可以绕过 Firebase 认证。
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.config import settings
from app.core.security import verify_firebase_token

# HTTP Bearer 认证方案 — 自动从 Authorization 头提取令牌
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    验证 Firebase ID Token 并返回当前用户信息。

    作为 FastAPI 依赖项使用，注入到需要认证的路由处理函数中。
    FastAPI 会自动从请求的 Authorization: Bearer <token> 头中提取令牌。

    行为：
    - 正常模式：调用 verify_firebase_token() 验证令牌有效性
    - 开发模式（DEBUG=True 或 Firebase 未配置）：返回固定 dev-user

    Args:
        credentials: FastAPI 自动注入的 HTTP 认证凭证，
                     包含从请求头解析出的 Bearer Token。

    Returns:
        dict: 包含 "uid" 和 "email" 的用户信息字典。

    Raises:
        HTTPException 401: 令牌无效、过期或已撤销。
        HTTPException 501: Firebase Admin SDK 未安装。
    """
    token = credentials.credentials

    # 开发模式：跳过真实 Firebase 验证
    if settings.DEBUG or not settings.FIREBASE_PROJECT_ID:
        return {"uid": "dev-user", "email": "dev@tilezhan.app"}

    try:
        return await verify_firebase_token(token)
    except HTTPException:
        raise  # 直接透传已格式化的 HTTPException
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
