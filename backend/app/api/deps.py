"""
FastAPI 依赖注入 — 认证与数据库连接。

本模块定义了所有端点共用的 FastAPI 依赖项，通过 Depends() 注入到路由处理函数中。
依赖注入机制允许 FastAPI 在调用路由处理函数之前，自动解析并传入所需的参数，
从而解耦认证逻辑与业务逻辑，使代码更易测试、维护和复用。

模块职责：
1. 声明 HTTPBearer 安全方案实例 — 告诉 OpenAPI / Swagger 文档如何接收令牌
2. 提供 get_current_user 依赖 — 从请求头提取 Bearer Token 并验证 Firebase 身份

开发模式：
    当 settings.DEBUG 为 True 或 FIREBASE_PROJECT_ID 未配置时，
    get_current_user 返回固定的 dev-user 身份，无需真实 Firebase 令牌。
    这使得开发/测试环境可以绕过 Firebase 认证，降低本地开发门槛。

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

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.config import settings
from app.core.security import verify_firebase_token

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
    1. 如果 settings.DEBUG 为 True，直接返回开发用户 — 开发环境免配置
    2. 如果 FIREBASE_PROJECT_ID 为空或未配置，同样返回开发用户 — 降级到免认证模式
    3. 否则调用 verify_firebase_token(token) 走完整 Firebase 验证链路

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
            - 状态码 501 (NOT_IMPLEMENTED)：当 Firebase Admin SDK 未安装
              或未正确初始化时抛出（由 verify_firebase_token 内部触发）。
    """
    # 从 HTTPBearer 解析出的凭证对象中提取原始 Token 字符串
    token = credentials.credentials

    # ── 开发模式分支 ──
    # 当 DEBUG 开启或 Firebase 项目 ID 未配置时，直接返回硬编码的开发用户。
    # 这样本地开发人员无需配置 Firebase 服务账号即可启动后端服务。
    if settings.DEBUG or not settings.FIREBASE_PROJECT_ID:
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
    except Exception as e:
        # 捕获所有其他未预料的异常（网络故障、SDK 内部错误等），
        # 统一包装为 401 返回给客户端，避免泄露内部实现细节。
        # 注意：生产环境应在此处添加结构化日志记录，
        # 便于后续排查 Firebase 集成问题。
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )
