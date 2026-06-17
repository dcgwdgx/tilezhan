/// 用户学习进度模型。
///
/// 以不可变数据类的形式追踪用户在学习系统中的核心进度指标，
/// 包括 ELo 竞技评分、等级、累计复习次数、连续活跃天数（连胜）
/// 以及最后一次活跃的时间戳。
///
/// 设计要点：
/// - **不可变性**：所有字段均为 [int] 且标记为 [final]，
///   外部代码无法直接修改字段值，必须通过 [copyWith] 创建新实例。
/// - **默认值语义**：构造函数为每个字段提供合理的初始值，
///   新用户可以直接使用默认构造，无需传递任何参数。
/// - **轻量级拷贝**：[copyWith] 仅替换显式传入的非 `null` 字段，
///   其余字段自动沿用当前实例的值，避免手写大量样板代码。
///
/// 使用示例：
/// ```dart
/// // 新用户默认进度
/// const newcomer = UserProgress();
///
/// // 完成一轮复习后更新评分与次数
/// final updated = newcomer.copyWith(
///   elo: 1050,
///   totalReviews: 1,
///   lastActiveAt: DateTime.now().millisecondsSinceEpoch,
/// );
/// ```
class UserProgress {
  /// 当前 ELo 评分。
  ///
  /// ELo 是一种广泛应用于棋类与竞技游戏的动态评分算法。
  /// 在本系统中，ELo 用于衡量用户对所学内容的掌握程度：
  /// - 初始值为 [1000]，代表新用户的基线水平。
  /// - 答对题目后根据对手难度与分差奖励若干分数。
  /// - 答错题目后根据同样规则扣除若干分数。
  /// - 分值越高表示掌握越扎实，越低表示需要更多复习。
  ///
  /// 取值范围：理论上无上限，实际通常在 0~3000 之间波动。
  final int elo;

  /// 当前等级。
  ///
  /// 等级是一个离散的进度指标，基于 [elo] 或其他规则计算得出。
  /// - 初始值为 [1]。
  /// - 每升一级代表用户达到了一个新的学习里程碑。
  /// - 等级计算逻辑不在此模型中实现，由业务层负责推导并
  ///   通过 [copyWith] 写入。
  ///
  /// 等级 >= 1，通常不会倒退（除非管理后台强制调整）。
  final int level;

  /// 累计复习总次数。
  ///
  /// 记录用户自注册以来完成的复习轮次总数。
  /// - 初始值为 [0]。
  /// - 每次用户完成一轮复习（无论正确率高低），此值递增 1。
  /// - 可用于计算复习频率、活跃度趋势等统计指标。
  /// - 与 [streak] 不同，此字段只增不减，永不重置。
  final int totalReviews;

  /// 连续活跃天数（连胜）。
  ///
  /// 记录用户最近连续每天至少完成一次复习的天数。
  /// - 初始值为 [0]。
  /// - 用户在某一天完成至少一次复习后，[streak] 递增 1。
  /// - 如果某一天用户未进行任何复习，[streak] 重置为 0。
  /// - 一天的定义由业务层根据服务器时区或用户本地时区决定，
  ///   本模型不处理时区逻辑。
  ///
  /// 可用于排行榜、连击奖励、徽章系统等激励机制。
  final int streak;

  /// 最后一次活跃时间的 Unix 时间戳（毫秒）。
  ///
  /// 记录用户最后一次与学习系统交互（做题、复习、登录等）的时刻。
  /// - 初始值为 [0]，表示用户从未活跃过。
  /// - 每次交互后由业务层更新为 `DateTime.now().millisecondsSinceEpoch`。
  /// - [0] 值可用于筛选从未活跃的"僵尸用户"。
  ///
  /// 用于判断用户是否处于活跃状态、间隔天数计算、流失预警等场景。
  final int lastActiveAt;

  /// 创建 [UserProgress] 实例。
  ///
  /// 所有参数均为可选命名参数，带有默认值：
  /// - [elo] 默认为 `1000`（ELo 基线分）。
  /// - [level] 默认为 `1`（起始等级）。
  /// - [totalReviews] 默认为 `0`（尚未进行复习）。
  /// - [streak] 默认为 `0`（无连胜记录）。
  /// - [lastActiveAt] 默认为 `0`（从未活跃）。
  ///
  /// 标记为 [const]，允许编译时常量构造（如 `const UserProgress()`），
  /// 有利于 Flutter 的 widget 重建优化与状态比较。
  ///
  /// 示例：
  /// ```dart
  /// // 使用全部默认值
  /// const defaultProgress = UserProgress();
  ///
  /// // 指定具体初始值
  /// const seededProgress = UserProgress(elo: 1200, level: 3);
  /// ```
  const UserProgress({
    this.elo = 1000,
    this.level = 1,
    this.totalReviews = 0,
    this.streak = 0,
    this.lastActiveAt = 0,
  });

  /// 创建当前实例的浅拷贝，选择性覆盖指定字段。
  ///
  /// 这是不可变数据模型的惯用模式，用于在不修改原始实例的前提下
  /// 生成一个部分更新的新实例。
  ///
  /// 参数：
  /// - 每个命名参数对应一个字段，类型为可空 [int?]。
  /// - 传入 `null`（或省略该参数）表示沿用当前实例的对应值。
  /// - 传入非 `null` 值表示在新实例中使用该值。
  ///
  /// 返回：
  /// - 一个新的 [UserProgress] 实例，字段值由传入参数与当前值合并得出。
  /// - 如果所有参数均为 `null`（默认全省略），返回一个与原实例
  ///   字段值完全相同的副本（语义上等价，但不保证引用相等）。
  ///
  /// 使用示例：
  /// ```dart
  /// final origin = UserProgress(elo: 1000, totalReviews: 5);
  ///
  /// // 仅更新 elo，其余字段不变
  /// final updated = origin.copyWith(elo: 1100);
  /// // updated.elo == 1100, updated.totalReviews == 5
  ///
  /// // 同时更新多个字段
  /// final multi = origin.copyWith(level: 3, streak: 7);
  /// // multi.level == 3, multi.streak == 7, multi.elo == 1000
  /// ```
  UserProgress copyWith({
    int? elo,
    int? level,
    int? totalReviews,
    int? streak,
    int? lastActiveAt,
  }) =>
      UserProgress(
        elo: elo ?? this.elo,
        level: level ?? this.level,
        totalReviews: totalReviews ?? this.totalReviews,
        streak: streak ?? this.streak,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );
}
