"""
Firebase Admin SDK — 懒加载初始化。

本模块提供 `get_firestore()` 函数，采用单例模式懒加载
Firebase Admin SDK。仅在首次调用时才初始化 Firestore 客户端，
避免应用启动时因配置缺失或 SDK 未安装而崩溃。

配置来源：
- settings.FIREBASE_PROJECT_ID: 项目 ID
- settings.FIREBASE_PRIVATE_KEY: 服务账号私钥（转义 \\n）
- settings.FIREBASE_CLIENT_EMAIL: 服务账号邮箱
- settings.FIRESTORE_DATABASE: Firestore 数据库 ID

若任一配置缺失或 SDK 未安装，返回 None 以允许优雅降级。
"""

_db = None


def get_firestore():
    """
    获取 Firestore 客户端实例（单例懒加载）。

    首次调用时：
    1. 检查 Firebase 配置是否完整（FIREBASE_PROJECT_ID 非空）
    2. 用服务账号凭证初始化 Firebase Admin SDK
    3. 创建并缓存 Firestore 客户端

    后续调用直接返回缓存的实例。

    Returns:
        firestore.Client | None: Firestore 客户端实例；
        若配置缺失或 SDK 初始化失败则返回 None。

    Note:
        私钥中的 \\n 需要替换为真正的换行符，因为环境变量中
        的换行符被转义存储。
    """
    global _db
    if _db is not None:
        return _db
    try:
        from firebase_admin import credentials, initialize_app, firestore
        from app.config import settings

        # 配置不完整时跳过初始化，允许应用在无 Firebase 环境中运行
        if not settings.FIREBASE_PROJECT_ID:
            return None

        cred = credentials.Certificate({
            "type": "service_account",
            "project_id": settings.FIREBASE_PROJECT_ID,
            "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
            "client_email": settings.FIREBASE_CLIENT_EMAIL,
            "token_uri": "https://oauth2.googleapis.com/token",
        })
        initialize_app(cred)
        _db = firestore.client(database_id=settings.FIRESTORE_DATABASE)
    except (ImportError, ValueError):
        # SDK 未安装或凭证格式错误 → 优雅降级
        _db = None
    return _db
