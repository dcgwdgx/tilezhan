import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../providers/storage_provider.dart';
import 'srs_item.dart';
import 'srs_engine.dart';

/// All known SRS items loaded from storage.
/// Per design: FutureProvider for async load from Hive/Firestore.
final srsItemsProvider = FutureProvider<Map<String, SrsItem>>((ref) async {
  final storage = await ref.watch(storageServiceProvider.future);
  final raw = storage.getJson(StorageService.kSrsItems);
  return raw.map((k, v) => MapEntry(k, SrsItem.fromJson(v as Map<String, dynamic>)));
});

/// Items due for review, sorted by errorWeight descending (design spec §6.2).
final dueItemsProvider = Provider<List<SrsItem>>((ref) {
  final itemsAsync = ref.watch(srsItemsProvider);
  final items = itemsAsync.valueOrNull ?? {};
  final now = DateTime.now().millisecondsSinceEpoch;
  return items.values
      .where((i) => i.nextReviewAt <= now)
      .toList()
    ..sort((a, b) => b.errorWeight.compareTo(a.errorWeight));
});

/// Notifier for recording reviews and updating SRS state.
final srsNotifierProvider = NotifierProvider<SrsReviewNotifier, Map<String, SrsItem>>(SrsReviewNotifier.new);

class SrsReviewNotifier extends Notifier<Map<String, SrsItem>> {
  StorageService? _storage;

  @override
  Map<String, SrsItem> build() {
    ref.watch(storageServiceProvider).whenData((s) {
      _storage = s;
      final raw = s.getJson(StorageService.kSrsItems);
      state = raw.map((k, v) => MapEntry(k, SrsItem.fromJson(v as Map<String, dynamic>)));
    });
    return {};
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
    final createdAt = existing?.createdAt ?? (quality < 3 ? now : 0);

    final (newEf, newReps, newInterval) = SrsEngine.calculate(ef, reps, interval, quality);
    final nextReviewAt = now + Duration(days: newInterval).inMilliseconds;

    state = {
      ...state,
      itemId: SrsItem(
        itemId: itemId, type: type,
        ef: newEf, reps: newReps, interval: newInterval,
        nextReviewAt: nextReviewAt, errors: errors,
        createdAt: createdAt, lastReviewedAt: now,
      ),
    };
    _save();
  }
}
