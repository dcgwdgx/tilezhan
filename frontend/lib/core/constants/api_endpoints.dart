/// API 端点常量定义文件 / API endpoint constants definition.
///
/// 集中管理所有后端 REST API 路径占位符。所有端点均基于 [ApiEndpoints.baseUrl]
/// 拼接完整 URL，便于后端部署后统一切换基地址。
///
/// Values are placeholders until the backend is deployed. All endpoints are
/// constructed from [ApiEndpoints.baseUrl] for easy base URL switching.
///
/// 端点分组:
/// - Auth: 注册、登录
/// - User: 用户信息、学习进度
/// - Puzzles: 每日牌局、闪卡、何切题、手牌评估
/// - SRS: 间隔重复系统同步与报告
/// - IAP: 内购产品与订阅

/// 后端 REST API 端点静态常量集合。
///
/// Backend REST API endpoint constants. All URLs are constructed from
/// [baseUrl] so that switching environments (dev/staging/prod) requires
/// changing only one constant.

class ApiEndpoints {
  /// 后端 API 基地址 / Base URL for the backend API.
  /// 部署后替换为实际域名 / Replace with actual domain after deployment.
  static const baseUrl = 'https://tz.slxing.com/api/v1';

  // ---- Auth 认证模块 ----
  /// 用户注册 / Register a new account.
  static const register = '$baseUrl/auth/register';
  /// 用户登录 / Log in with credentials.
  static const login = '$baseUrl/auth/login';

  // ---- User 用户模块 ----
  /// 获取用户个人信息 / Fetch user profile.
  static const profile = '$baseUrl/user/profile';
  /// 获取用户学习进度 / Fetch learning progress.
  static const progress = '$baseUrl/user/progress';

  // ---- Puzzles 题目模块 ----
  /// 每日牌局题目 / Daily mahjong puzzle.
  static const daily = '$baseUrl/puzzles/daily';
  /// 闪卡题目列表 / Flashcard puzzle list.
  static const flashcards = '$baseUrl/puzzles/flashcards';
  /// 何切题（牌效率选择题）/ Nanikiru (tile efficiency) puzzles.
  static const nanikiru = '$baseUrl/puzzles/nanikiru';
  /// 手牌评估 / Hand evaluation.
  static const evaluate = '$baseUrl/puzzles/evaluate';

  // ---- SRS 间隔重复模块 ----
  /// SRS 数据同步 / Spaced repetition sync.
  static const srsSync = '$baseUrl/srs/sync';
  /// SRS 学习报告 / Spaced repetition report.
  static const srsReport = '$baseUrl/srs/report';

  // ---- IAP 内购模块 ----
  /// 内购产品列表 / Available IAP products.
  static const products = '$baseUrl/products';
  /// 订阅状态 / Subscription status endpoint.
  static const subscription = '$baseUrl/subscription';
}
