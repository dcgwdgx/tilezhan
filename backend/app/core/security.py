"""
Firebase 身份认证令牌验证 — 支持开发模式无 SDK 运行。

本模块是系统的安全网关，提供 `verify_firebase_token` 函数，用于验证客户端
通过 Authorization Header 提交的 Firebase ID Token（Bearer 方式）。

核心设计决策：
- 懒加载（Lazy Import）：仅在首次验证调用时才导入 firebase_admin 模块。
  这意味着开发环境中即使未安装该 SDK，应用也能正常启动；只有实际触发
  身份验证时才会报错，避免因缺少 SDK 导致整个应用瘫痪。
- 令牌撤销检测（Token Revocation Check）：每次验证都会向 Firebase 服务端
  确认令牌是否已被撤销（如用户登出或密码重置后），加强安全性。
- 异常分类：根据 Firebase SDK 抛出的错误信息关键字（expired / revoked），
  返回不同语义的 HTTP 状态码和错误描述，方便客户端做差异化 UI 处理。

验证流程（按优先级）：
1. 尝试导入 firebase_admin 并调用 verify_id_token + 吊销检查
2. 若 SDK 未安装（ImportError）→ 返回 501 Not Implemented
3. 若令牌过期（含 "expired" 关键字）→ 返回 401 Unauthorized
4. 若令牌已撤销（含 "revoked" 关键字）→ 返回 401 Unauthorized
5. 其他验证失败（格式错误、无效签名等）→ 返回 401 Unauthorized

典型调用位置：
- app/api/deps.py 中的 get_current_user 依赖注入函数
- 所有受保护路由的 Depends(get_current_user) 调用链
"""

# --- 标准库 / 第三方导入 ---
# FastAPI 的 HTTPException：统一抛出 HTTP 错误响应
# FastAPI 的 status：语义化 HTTP 状态码常量（如 401, 501）
from fastapi import HTTPException, status


# ======================================================================
#  公开函数
# ======================================================================


async def verify_firebase_token(token: str) -> dict:
    """
    验证 Firebase ID Token 并返回解码后的用户信息字典。

    本函数是系统身份认证的唯一入口。采用懒加载策略在运行时按需导入
    firebase_admin，避免在开发或 CI 环境中因 SDK 未安装导致应用启动失败。

    认证流程：
        1. 延迟导入 firebase_admin.auth（首次调用时触发）
        2. 调用 verify_id_token 验证令牌签名、有效期、签发者等
        3. 设置 check_revoked=True，向 Firebase 后端额外查询令牌是否已被吊销
        4. 根据异常类型返回不同粒度的 HTTP 错误响应

    Args:
        token: 客户端通过 HTTP Authorization: Bearer <token> 头提交的
               Firebase ID Token 原始字符串（通常由前端 Firebase SDK 获取）。

    Returns:
        dict: 解码后的 JWT payload 字典，常用字段包括：
            - uid (str): Firebase Auth 用户唯一标识符
            - email (str): 用户邮箱（若使用邮箱登录，可能为 None）
            - email_verified (bool): 邮箱是否已验证
            - name (str): 用户显示名（可能为 None）
            - picture (str): 用户头像 URL（可能为 None）
            - iss (str): 签发者，固定为 https://securetoken.google.com/<project_id>
            - aud (str): 受众，即 Firebase 项目 ID
            - iat (int): 令牌签发时间戳（Unix 秒）
            - exp (int): 令牌过期时间戳（Unix 秒）
            - sub (str): 用户 UID，与 uid 字段值相同
            - auth_time (int): 用户最近一次登录的时间戳（Unix 秒）
            - firebase.sign_in_provider (str): 登录方式（如 password, google.com）

    Raises:
        HTTPException 501:
            Firebase Admin SDK 未安装。客户端应提示运维人员或开发者
            执行 `pip install firebase-admin` 并正确设置
            GOOGLE_APPLICATION_CREDENTIALS 环境变量。
        HTTPException 401:
            令牌验证失败，具体原因见 detail 字段：
            - "Token expired": 令牌已过期（exp 早于当前时间），
              客户端应引导用户重新登录。
            - "Token revoked": 令牌已被 Firebase 服务端吊销
              （用户登出、密码重置等原因），客户端应清除本地会话。
            - 其他字符串: 原始错误信息（格式错误、签名无效等）。
    """
    try:
        # ============================================================
        # 步骤 1：懒加载 Firebase Admin SDK
        # ============================================================
        # 仅在实际需要验证时才导入，避免开发环境缺少 SDK 导致模块导入即崩溃。
        # 使用 `auth as firebase_auth` 别名避免与 FastAPI 的 auth 冲突。
        from firebase_admin import auth as firebase_auth

        # ============================================================
        # 步骤 2：验证令牌签名 + 有效期 + 吊销状态
        # ============================================================
        # check_revoked=True 会向 Firebase 后端发起额外网络请求，
        # 查询该令牌是否已被标记为吊销（用户登出/密码重置/管理员禁用等操作触发）。
        # 虽然增加了一次网络往返延迟，但对安全性的提升是值得的。
        # 返回值为解码后的 JWT payload 字典，直接透传给上层调用者。
        return firebase_auth.verify_id_token(token, check_revoked=True)

    except ImportError:
        # ============================================================
        # 异常路径 A：Firebase Admin SDK 未安装
        # ============================================================
        # ImportError 说明 firebase_admin 包不存在或未正确安装。
        # 返回 501（服务器未实现）而非 500，语义更精确地表达
        # "功能逻辑已写但运行时缺失依赖"。
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Firebase Admin SDK not installed. Run: pip install firebase-admin",
        )

    except Exception as e:
        # ============================================================
        # 异常路径 B：令牌验证失败（过期 / 吊销 / 其他）
        # ============================================================
        # Firebase SDK 抛出的异常类型多样（CertificateFetchError,
        # ExpiredIdTokenError, RevokedIdTokenError, InvalidIdTokenError 等）。
        # 这里统一捕获 Exception，通过错误消息关键字区分具体原因，
        # 避免 import 过多 SDK 内部异常类型增加耦合。
        err = str(e)

        # 令牌过期：JWT 的 exp 字段早于当前时间
        if "expired" in err.lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token expired",
            )

        # 令牌已吊销：用户登出或密码已重置，令牌被 Firebase 后端标记为无效
        if "revoked" in err.lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token revoked",
            )

        # 兜底：其他验证失败（无效签名、格式错误、项目 ID 不匹配等）
        # 将原始错误信息透传，方便客户端日志排查
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )
