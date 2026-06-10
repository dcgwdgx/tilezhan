import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../providers/storage_provider.dart';
import 'srs_item.dart';
import 'srs_engine.dart';

/// All known SRS items loaded from storage.
final srsItemsProvider = StateNotifierProvider<SrsNotifier, Map<String, SrsItem>>((ref) {
  final storageAsync = ref.watch(storageServiceProvider);
  return SrsNotifier(storageAsync.valueOrNull);
});

/// Items due for review (nextReviewAt <= now).
final dueItemsProvider = Provider<List<SrsItem>>((ref) {
  final items = ref.watch(srsItemsProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  return items.values.where((i) => i.nextReviewAt <= now).toList()
    ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
});

class SrsNotifier extends StateNotifier<Map<String, SrsItem>> {
  final StorageService? _storage;
  SrsNotifier(this._storage) : super({}) {
    _load();
  }

  void _load() {
    if (_storage == null) return;
    final raw = _storage!.getJson(StorageService.kSrsItems);
    state = raw.map((k, v) => MapEntry(k, SrsItem.fromJson(v as Map<String, dynamic>)));
  }

  void _save() {
    if (_storage == null) return;
    _storage!.setJson(StorageService.kSrsItems,
      state.map((k, v) => MapEntry(k, v.toJson())));
  }

  /// Record a review and update the SRS schedule.
  void recordReview(String itemId, String type, int quality) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = state[itemId];
    final ef = existing?.ef ?? 2.5;
    final reps = existing?.reps ?? 0;
    final interval = existing?.interval ?? 1;
    final errors = (existing?.errors ?? 0) + (quality < 3 ? 1 : 0);

    final (newEf, newReps, newInterval) = SrsEngine.calculate(ef, reps, interval, quality);
    final nextReviewAt = now + Duration(days: newInterval).inMilliseconds;

    state = {
      ...state,
      itemId: SrsItem(
        itemId: itemId, type: type,
        ef: newEf, reps: newReps, interval: newInterval,
        nextReviewAt: nextReviewAt, errors: errors,
      ),
    };
    _save();
  }
}
