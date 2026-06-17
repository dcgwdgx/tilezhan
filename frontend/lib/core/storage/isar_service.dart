/// Isar 结构化存储服务 —— 离线优先的本地数据库。
///
/// 数据模式（Schema）：[LocalProgress]、[LocalSRSItem]、[SyncOperation]。
///
/// Isar 存储服务，作为所有结构化应用数据的唯一事实来源（source of truth）：
/// - **SRS 数据** —— 基于 [LocalSRSItem] 的间隔重复记忆法（spaced-repetition）题目状态。
/// - **进度数据** —— 通过 [LocalProgress] 记录每个模块的拼图完成情况和错误次数。
/// - **离线同步** —— 队列化的同步操作（[SyncOperation]），用于延迟上传。
///
/// 本服务采用单例模式（singleton pattern）。在访问 [IsarService.instance] 之前，
/// 必须在应用启动时调用一次 [IsarService.initialize]。
///
/// 依据设计规范：tilezhan-v2-design.md —— 使用 Isar 存储结构化离线数据。
///
/// Isar structured storage service — offline-first local database.
///
/// Schema: [LocalProgress], [LocalSRSItem], [SyncOperation].
///
/// IsarService acts as the source of truth for all structured app data:
/// - **SRS data** — spaced-repetition item states backed by [LocalSRSItem].
/// - **Progress** — per-module puzzle completion and error counts via [LocalProgress].
/// - **Offline sync** — queued sync operations ([SyncOperation]) for deferred upload.
///
/// The service follows a singleton pattern. Call [IsarService.initialize] once at
/// app startup before accessing [IsarService.instance].
///
/// Per design spec: tilezhan-v2-design.md — Isar for structured offline data.

/// 单个模块的本地拼图进度。
///
/// 记录该模块中哪些牌（tile）已经完成、每张牌的错误次数，
/// 以及最后一次同步的时间戳，用于离线数据对账（offline reconciliation）。
///
/// Local puzzle progress for a single module.
///
/// Tracks which tiles have been completed and the error counts per tile,
/// together with the last-synced timestamp for offline reconciliation.
class LocalProgress {
  /// Isar 自增主键 ID（首次保存前为 null）。
  /// Auto-incremented Isar ID (null before first save).
  final int? isarId;

  /// 模块标识符（例如 `"sima_yi"`、`"zhugeliang"`）。
  /// Module identifier (e.g. `"sima_yi"`, `"zhugeliang"`).
  final String moduleId;

  /// 该模块中用户已完成的所有牌（tile）的 ID 列表。
  /// List of tile IDs the user has already completed in this module.
  final List<String> completedTileIds;

  /// 以牌 ID 为键的错误次数映射表（用于 SRS 难度调节）。
  /// Error-count map keyed by tile ID (used for SRS difficulty tuning).
  final Map<String, int> errorCounts;

  /// 该模块最近一次云端同步的时间戳。
  /// Timestamp of the most recent cloud sync for this module.
  final DateTime lastSynced;

  /// 创建一个 [LocalProgress] 记录。
  ///
  /// [moduleId] 和 [lastSynced] 为必填项；[completedTileIds] 和
  /// [errorCounts] 默认为空集合。
  ///
  /// Creates a [LocalProgress] record.
  ///
  /// [moduleId] and [lastSynced] are required; [completedTileIds] and
  /// [errorCounts] default to empty collections.
  const LocalProgress({
    this.isarId,
    required this.moduleId,
    this.completedTileIds = const [],
    this.errorCounts = const {},
    required this.lastSynced,
  });
}

/// 本地存储的单条间隔重复记忆法（SRS）记录。
///
/// 与后端 SRS 模型结构一致，额外增加 [pendingSync] 标志位。
/// 由 [SrsEngine] 使用，用于安排复习时间并驱动 SRS 答题循环。
///
/// A single spaced-repetition item stored locally.
///
/// Mirrors the backend SRS model with an additional [pendingSync] flag.
/// Used by [SrsEngine] to schedule reviews and drive the SRS quiz loop.
class LocalSRSItem {
  /// Isar 自增主键 ID（首次保存前为 null）。
  /// Auto-incremented Isar ID (null before first save).
  final int? isarId;

  /// 本条 SRS 状态所属的牌（题目）标识符。
  /// The tile (question) identifier this SRS state belongs to.
  final String tileId;

  /// 拼图类型区分符（例如 `"name"`、`"poem"`、`"event"`）。
  /// Puzzle type discriminator (e.g. `"name"`, `"poem"`, `"event"`).
  final String puzzleType;

  /// SM-2 算法中的简易度因子（easiness factor）；初始值为 2.5（SRS 默认值）。
  /// SM-2 easiness factor; starts at 2.5 (SRS default).
  final double easinessFactor;

  /// 当前复习间隔，单位为天。
  /// Current review interval in days.
  final int intervalDays;

  /// 连续正确回忆的次数。
  /// Number of consecutive correct recalls.
  final int repetitions;

  /// 本条记录下一次应复习的最早日期/时间。
  /// Earliest date/time when this item should be reviewed again.
  final DateTime nextReview;

  /// 是否存在尚未推送到后端的本地变更。
  /// Whether this item has local changes that need to be pushed to the backend.
  final bool pendingSync;

  /// 创建一个 [LocalSRSItem]。
  ///
  /// [tileId]、[puzzleType] 和 [nextReview] 为必填项。
  /// [easinessFactor] 默认为 2.5，[intervalDays] 默认为 1，[repetitions] 默认为 0。
  ///
  /// Creates a [LocalSRSItem].
  ///
  /// [tileId], [puzzleType], and [nextReview] are required.
  /// [easinessFactor] defaults to 2.5, [intervalDays] to 1, [repetitions] to 0.
  const LocalSRSItem({
    this.isarId,
    required this.tileId,
    required this.puzzleType,
    this.easinessFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    required this.nextReview,
    this.pendingSync = false,
  });
}

/// 离线队列中的同步操作，待网络恢复后重放（replay）。
///
/// 每条记录对应一次 API 调用 —— 包含接口 URL、JSON 载荷、
/// 以及是否已投递的标志位。后台同步任务按从旧到新（FIFO）的顺序
/// 消费 [synced] 为 `false` 的记录。
///
/// An offline-queued sync operation to be replayed when connectivity returns.
///
/// Each record captures one API call — endpoint URL, JSON payload, and
/// whether it has already been delivered. A background sync task drains
/// records where [synced] is `false` oldest-first.
class SyncOperation {
  /// Isar 自增主键 ID（首次保存前为 null）。
  /// Auto-incremented Isar ID (null before first save).
  final int? isarId;

  /// 目标 API 接口路径（例如 `"/api/v1/srs/review"`）。
  /// Target API endpoint path (e.g. `"/api/v1/srs/review"`).
  final String endpoint;

  /// 可 JSON 序列化的请求体（request body）。
  /// JSON-serialisable request body.
  final Map<String, dynamic> payload;

  /// 本条操作最初创建的时间（用于 FIFO 排序）。
  /// When this operation was originally created (for FIFO ordering).
  final DateTime createdAt;

  /// 为 `true` 时表示本条操作已成功投递到后端。
  /// `true` after the operation has been successfully delivered to the backend.
  final bool synced;

  /// 创建一个 [SyncOperation]。
  ///
  /// [endpoint]、[payload] 和 [createdAt] 为必填项。
  /// [synced] 默认为 `false`。
  ///
  /// Creates a [SyncOperation].
  ///
  /// [endpoint], [payload], and [createdAt] are required.
  /// [synced] defaults to `false`.
  const SyncOperation({
    this.isarId,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    this.synced = false,
  });
}

/// 管理 Isar 数据库实例的单例服务。
///
/// 在应用启动时调用一次 [IsarService.initialize]，之后通过
/// [IsarService.instance] 访问共享实例。所有结构化数据 ——
/// 进度、SRS 记录和同步操作 —— 均存储在本服务暴露的 Isar 集合中。
///
/// 当前为轻量级桩代码（stub）；数据模式类（[LocalProgress]、[LocalSRSItem]、
/// [SyncOperation]）已在上面定义。Isar 数据库的接线和集合访问器
/// 将在集成 `isar` / `isar_flutter_libs` 包后补充实现。
///
/// Singleton service that owns the Isar database instance.
///
/// Call [IsarService.initialize] once at app startup, then access the shared
/// instance via [IsarService.instance]. All structured data — progress, SRS
/// items, and sync operations — lives in Isar collections exposed by this service.
///
/// Currently a lightweight stub; schema classes ([LocalProgress], [LocalSRSItem],
/// [SyncOperation]) are defined above. The Isar DB wiring and collection accessors
/// will be added when `isar` / `isar_flutter_libs` are integrated.
class IsarService {
  // 单例实例的私有静态缓存（null 表示尚未初始化）。
  // Private static cache of the singleton instance (null = not yet initialized).
  static IsarService? _instance;

  /// 共享的单例实例。
  ///
  /// 如果在调用 [initialize] 之前访问，将抛出 [StateError]。
  ///
  /// Shared singleton instance.
  ///
  /// Throws [StateError] if accessed before [initialize] is called.
  static IsarService get instance =>
      _instance ?? (throw StateError('IsarService not initialized'));

  /// 启动（bootstrap）IsarService 单例。
  ///
  /// 在任何其他 [IsarService] 调用之前必须先 await 此方法。
  /// 未来还将在此方法中打开 Isar 数据库并注册所有数据模式（schemas）。
  ///
  /// Bootstraps the IsarService singleton.
  ///
  /// Must be awaited before any other [IsarService] call.
  /// In the future this will also open the Isar database and register schemas.
  static Future<void> initialize() async {
    // 创建单例实例并赋值给静态缓存。
    // Create the singleton instance and assign it to the static cache.
    _instance = IsarService();
  }
}
