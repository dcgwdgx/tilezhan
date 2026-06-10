class UserProgress {
  final int elo;
  final int level;
  final int totalReviews;
  final int streak;
  final int lastActiveAt; // epoch ms

  const UserProgress({
    this.elo = 1000,
    this.level = 1,
    this.totalReviews = 0,
    this.streak = 0,
    this.lastActiveAt = 0,
  });

  UserProgress copyWith({int? elo, int? level, int? totalReviews, int? streak, int? lastActiveAt}) =>
      UserProgress(
        elo: elo ?? this.elo, level: level ?? this.level,
        totalReviews: totalReviews ?? this.totalReviews,
        streak: streak ?? this.streak, lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );
}
