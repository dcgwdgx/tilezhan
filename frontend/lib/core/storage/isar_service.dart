/// Isar local database service.
///
/// Schema: LocalProgress, LocalSRSItem, CachedPuzzle, SyncOperation.
/// Used as source of truth for offline-first data.

class LocalProgress {
  final int? isarId;
  final String moduleId;
  final List<String> completedTileIds;
  final Map<String, int> errorCounts;
  final DateTime lastSynced;

  const LocalProgress({
    this.isarId,
    required this.moduleId,
    this.completedTileIds = const [],
    this.errorCounts = const {},
    required this.lastSynced,
  });
}

class LocalSRSItem {
  final int? isarId;
  final String tileId;
  final String puzzleType;
  final double easinessFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReview;
  final bool pendingSync;

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

class SyncOperation {
  final int? isarId;
  final String endpoint;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool synced;

  const SyncOperation({
    this.isarId,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    this.synced = false,
  });
}

class IsarService {
  static IsarService? _instance;
  static IsarService get instance =>
      _instance ?? (throw StateError('IsarService not initialized'));

  static Future<void> initialize() async {
    _instance = IsarService();
  }
}
