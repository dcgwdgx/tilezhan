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

/// Local puzzle progress for a single module.
///
/// Tracks which tiles have been completed and the error counts per tile,
/// together with the last-synced timestamp for offline reconciliation.
class LocalProgress {
  /// Auto-incremented Isar ID (null before first save).
  final int? isarId;

  /// Module identifier (e.g. `"sima_yi"`, `"zhugeliang"`).
  final String moduleId;

  /// List of tile IDs the user has already completed in this module.
  final List<String> completedTileIds;

  /// Error-count map keyed by tile ID (used for SRS difficulty tuning).
  final Map<String, int> errorCounts;

  /// Timestamp of the most recent cloud sync for this module.
  final DateTime lastSynced;

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

/// A single spaced-repetition item stored locally.
///
/// Mirrors the backend SRS model with an additional [pendingSync] flag.
/// Used by [SrsEngine] to schedule reviews and drive the SRS quiz loop.
class LocalSRSItem {
  /// Auto-incremented Isar ID (null before first save).
  final int? isarId;

  /// The tile (question) identifier this SRS state belongs to.
  final String tileId;

  /// Puzzle type discriminator (e.g. `"name"`, `"poem"`, `"event"`).
  final String puzzleType;

  /// SM-2 easiness factor; starts at 2.5 (SRS default).
  final double easinessFactor;

  /// Current review interval in days.
  final int intervalDays;

  /// Number of consecutive correct recalls.
  final int repetitions;

  /// Earliest date/time when this item should be reviewed again.
  final DateTime nextReview;

  /// Whether this item has local changes that need to be pushed to the backend.
  final bool pendingSync;

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

/// An offline-queued sync operation to be replayed when connectivity returns.
///
/// Each record captures one API call — endpoint URL, JSON payload, and
/// whether it has already been delivered. A background sync task drains
/// records where [synced] is `false` oldest-first.
class SyncOperation {
  /// Auto-incremented Isar ID (null before first save).
  final int? isarId;

  /// Target API endpoint path (e.g. `"/api/v1/srs/review"`).
  final String endpoint;

  /// JSON-serialisable request body.
  final Map<String, dynamic> payload;

  /// When this operation was originally created (for FIFO ordering).
  final DateTime createdAt;

  /// `true` after the operation has been successfully delivered to the backend.
  final bool synced;

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
  static IsarService? _instance;

  /// Shared singleton instance.
  ///
  /// Throws [StateError] if accessed before [initialize] is called.
  static IsarService get instance =>
      _instance ?? (throw StateError('IsarService not initialized'));

  /// Bootstraps the IsarService singleton.
  ///
  /// Must be awaited before any other [IsarService] call.
  /// In the future this will also open the Isar database and register schemas.
  static Future<void> initialize() async {
    _instance = IsarService();
  }
}
