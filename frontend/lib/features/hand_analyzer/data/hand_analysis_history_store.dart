import '../../../core/storage/storage_service.dart';
import '../domain/hand_analysis_history.dart';

/// Injectable persistence boundary for recent and favorite analyzer inputs.
abstract interface class HandAnalysisHistoryStore {
  HandAnalysisHistory read();

  Future<void> write(HandAnalysisHistory history);
}

/// Production adapter using one independent, versioned JSON file.
class StorageServiceHandAnalysisHistoryStore
    implements HandAnalysisHistoryStore {
  const StorageServiceHandAnalysisHistoryStore(this._storage);

  static const storageKey = 'hand_analysis_history_v1';

  final StorageService _storage;

  @override
  HandAnalysisHistory read() => HandAnalysisHistory.fromJson(
        _storage.getJson(storageKey),
      );

  @override
  Future<void> write(HandAnalysisHistory history) => _storage.setJson(
        storageKey,
        history.toJson(),
      );
}

/// Lightweight adapter for tests, previews, or a storage-unavailable fallback.
class InMemoryHandAnalysisHistoryStore implements HandAnalysisHistoryStore {
  InMemoryHandAnalysisHistoryStore([
    HandAnalysisHistory? initialValue,
  ]) : _value = initialValue ?? HandAnalysisHistory.empty();

  HandAnalysisHistory _value;

  @override
  HandAnalysisHistory read() => _value;

  @override
  Future<void> write(HandAnalysisHistory history) async {
    _value = history;
  }
}
