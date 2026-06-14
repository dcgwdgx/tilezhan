/// 用户学习进度模型 — 跟踪 ELo 评分、等级、总复习次数、连胜天数与最后活跃时间。
///
/// 所有字段均为 [int] 且不可变，通过 [copyWith] 派生出修改后的新实例。
class UserProgress {
  /// 当前 ELo 评分（默认 1000）。
  final int elo;

  /// 当前等级（默认 1）。
  final int level;

  /// 累计复习总次数。
  final int totalReviews;

  /// 连续活跃天数（连胜）。
  final int streak;

  /// 最后活跃时间的 epoch 毫秒值（0 表示从未活跃）。
  final int lastActiveAt;

  /// 创建用户进度实例，所有字段均有默认值。
  const UserProgress({
    this.elo = 1000,
    this.level = 1,
    this.totalReviews = 0,
    this.streak = 0,
    this.lastActiveAt = 0,
  });

  /// 返回当前实例的副本，仅替换传入的非 `null` 字段。
  UserProgress copyWith({int? elo, int? level, int? totalReviews, int? streak, int? lastActiveAt}) =>
      UserProgress(
        elo: elo ?? this.elo, level: level ?? this.level,
        totalReviews: totalReviews ?? this.totalReviews,
        streak: streak ?? this.streak, lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );
}
