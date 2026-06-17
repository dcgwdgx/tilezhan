"""
Firebase Admin SDK — 懒加载初始化模块。

================================================================================
模块职责
================================================================================

本模块提供 `get_firestore()` 函数，采用**单例模式**懒加载 Firebase Admin SDK。
仅在首次调用时才执行 SDK 初始化和 Firestore 客户端创建，避免以下问题：

  1. 应用启动时因 Firebase 配置缺失而崩溃（Allow graceful degradation）。
  2. 在不需要数据库的请求路径上浪费 Firebase 连接资源。
  3. 多次重复初始化导致内存中出现多个 SDK 实例。

================================================================================
配置来源（均从 settings 对象读取）
================================================================================

  - settings.FIREBASE_PROJECT_ID   : GCP 项目 ID（如 "my-project"）。
  - settings.FIREBASE_PRIVATE_KEY  : 服务账号 PEM 私钥，换行符被转义为 \\n。
  - settings.FIREBASE_CLIENT_EMAIL : 服务账号邮箱（如 "sa@<project>.iam.gserviceaccount.com"）。
  - settings.FIRESTORE_DATABASE    : Firestore 数据库 ID（默认 "(default)"）。

================================================================================
降级策略
================================================================================

若任一必填配置缺失、`firebase_admin` 包未安装、或凭证格式非法，
本模块不会抛出异常，而是返回 None。调用方应据此判断 Firebase 是否可用：

    db = get_firestore()
    if db is None:
        # Firebase 不可用，使用本地后备存储或返回错误
        ...

================================================================================
线程安全说明
================================================================================

当前实现不包含锁机制。在 WSGI/ASGI 多线程环境下，首次并发调用可能触发
多次初始化。对于大多数部署场景（gunicorn preload、单 worker 预热），
这不会造成实际问题。若需严格保证单次初始化，可在 `_db = None` 检查外
加 `threading.Lock`。

================================================================================
使用示例
================================================================================

    from app.core.firebase import get_firestore

    db = get_firestore()
    if db:
        doc = db.collection("users").document(uid).get()
"""

# ---------------------------------------------------------------------------
# 模块级私有变量：持有全局唯一的 Firestore 客户端实例（单例缓存）。
# 初始值为 None，表示"尚未初始化"。首次调用 get_firestore() 成功后将
# 被赋值为 firestore.Client 实例；初始化失败时保持 None。
# ---------------------------------------------------------------------------
_db = None


def get_firestore():
    """
    获取全局唯一的 Firestore 客户端实例（懒加载单例）。

    ============================================================================
    执行流程
    ============================================================================

    首次调用时（_db 为 None）：
      1. 导入 firebase_admin SDK 和项目配置模块。
      2. 校验 FIREBASE_PROJECT_ID 是否存在 — 若为空则直接返回 None，
         表示 Firebase 未被配置（而非运行时异常）。
      3. 将私钥字符串中的转义换行符 \\n 还原为真正的换行符 \\n，
         构造 google.oauth2.service_account.Credentials 字典。
      4. 调用 firebase_admin.initialize_app() 初始化默认 Firebase 应用。
      5. 调用 firestore.client() 创建客户端实例并缓存到模块变量 _db。

    后续调用时（_db 已缓存）：
      → 直接返回缓存的实例，跳过所有初始化逻辑。

    ============================================================================
    Args
    ============================================================================
        本函数不接受任何参数。所有配置均从 `app.config.settings` 对象中读取。

    ============================================================================
    Returns
    ============================================================================
        google.cloud.firestore.Client | None

        成功时返回一个已认证的 Firestore 客户端实例，调用方可用其执行
        CRUD、事务、批量写入等操作。

        返回 None 的情形：
          - FIREBASE_PROJECT_ID 为空字符串或 None（Firebase 未配置）。
          - firebase_admin 包未安装（ImportError）。
          - 服务账号凭证格式非法（ValueError，如私钥不是有效的 PEM）。

    ============================================================================
    Raises
    ============================================================================
        本函数不会向外抛出异常 — 所有可预见的错误均被内部捕获并转换为
        返回 None。这是刻意设计的"永不崩溃"安全网，让上层调用方可以
        安全地在路由、中间件、后台任务中随时调用。
    """
    # ---- 声明使用模块级单例变量 ----
    global _db

    # ---- 快速路径：已缓存则直接返回，避免重复导入和 SDK 初始化 ----
    if _db is not None:
        return _db

    try:
        # ---- 延迟导入：避免模块加载时就触发 SDK 依赖 ----
        from firebase_admin import credentials, initialize_app, firestore
        from app.config import settings

        # ---- 配置完整性检查：项目 ID 为必填项，缺失则提前退出 ----
        if not settings.FIREBASE_PROJECT_ID:
            return None

        # ---- 构造服务账号凭证 ----
        # 注意：环境变量中的换行符被存储为字面量 \\n（两个字符），
        # 必须还原为真正的换行符，否则私钥无法被 RSA 解析。
        # 其他字段（project_id、client_email、token_uri）直接透传。
        cred = credentials.Certificate({
            "type": "service_account",
            "project_id": settings.FIREBASE_PROJECT_ID,
            "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
            "client_email": settings.FIREBASE_CLIENT_EMAIL,
            "token_uri": "https://oauth2.googleapis.com/token",
        })

        # ---- 初始化 Firebase Admin SDK（全局默认应用） ----
        # 注意：firebase_admin 在进程生命周期内只应调用一次 initialize_app()。
        # 本模块通过 _db 缓存间接保证这一点 — 第二次调用会在快速路径返回。
        initialize_app(cred)

        # ---- 创建 Firestore 客户端 ----
        # database_id 指向特定的 Firestore 数据库（默认数据库 ID 为 "(default)"）。
        # 客户端实例是线程安全的，可在多线程环境中共享。
        _db = firestore.client(database_id=settings.FIRESTORE_DATABASE)

    except (ImportError, ValueError):
        # ---- 优雅降级：SDK 缺失或凭证格式错误 ----
        # ImportError : pip 未安装 firebase-admin 包。
        # ValueError  : Certificate() 收到的私钥不是有效 PEM（常见原因：
        #               replace("\\n", "\\n") 前的私钥仍含转义符，或私钥被截断）。
        # 将 _db 重置为 None 以确保失败后下次调用仍会重试初始化。
        _db = None

    # ---- 返回结果：客户端实例 或 None ----
    return _db
