"""
Firebase 身份认证令牌验证 — 支持开发模式无 SDK 运行。

本模块提供 `verify_firebase_token` 函数，用于验证客户端提交的
Firebase ID Token。采用懒加载策略：仅在实际调用时才导入
firebase_admin，避免开发环境中未安装 SDK 时启动失败。

验证流程：
1. 尝试导入 firebase_admin 并验证令牌
2. 若 SDK 未安装 → 返回 501 Not Implemented
3. 若令牌过期 → 返回 401 Unauthorized（含 "Token expired" 提示）
4. 若令牌已撤销 → 返回 401 Unauthorized（含 "Token revoked" 提示）
5. 其他验证失败 → 返回 401 Unauthorized
"""

from fastapi import HTTPException, status


async def verify_firebase_token(token: str) -> dict:
    """
    验证 Firebase ID Token 并返回解码后的用户信息。

    采用懒加载策略导入 firebase_admin，避免开发环境中
    未安装该 SDK 时导致整个应用启动失败。

    Args:
        token: 客户端提交的 Firebase ID Token 字符串。

    Returns:
        dict: 解码后的令牌 payload，包含 uid、email 等用户信息。

    Raises:
        HTTPException 501: Firebase Admin SDK 未安装。
        HTTPException 401: 令牌过期、已撤销或无效。
    """
    try:
        # 懒加载：仅在首次验证时才触发 Firebase Admin SDK 导入
        from firebase_admin import auth as firebase_auth
        return firebase_auth.verify_id_token(token, check_revoked=True)
    except ImportError:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Firebase Admin SDK not installed. Run: pip install firebase-admin",
        )
    except Exception as e:
        # 根据错误信息细分 HTTP 响应，方便客户端区分处理
        err = str(e)
        if "expired" in err.lower():
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired")
        if "revoked" in err.lower():
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
