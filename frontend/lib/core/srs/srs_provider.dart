/// SRS (Spaced Repetition System) state management via Riverpod.
///
/// Exposes the full review lifecycle:
/// - [srsItemsProvider] — async load of all SRS items from storage
/// - [dueItemsProvider] — items currently due, sorted by [SrsItem.errorWeight] descending
/// - [srsNotifierProvider] / [SrsReviewNotifier] — record reviews, recalculate SM-2
///   schedule, and persist back to storage
///
/// Design spec §6.2: items are prioritised by errorWeight so the hardest cards
/// surface first. Wrong answers (quality < 3) are scheduled for immediate
/// re-review; correct answers follow the standard SM-2 interval progression.
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/storage_service.dart';
import '../providers/storage_provider.dart';
import 'srs_engine.dart';
import 'srs_item.dart';

/// 将本地 SRS 数据同步到后端（JSON 序列化后 POST）。
///
/// 返回 (success, uploadedCount)。后端已部署但 HTTP 客户端待对接，
/// 当前仅序列化数据，不实际发送。
Future<(bool, int)> syncSrsToCloud(List<SrsItem> items) async {
  try {
    final data = jsonEncode(items.map((i) => i.toJson()).toList());
    // final res = await DioClient.instance.post(ApiEndpoints.srsSync, data: data);
    // return (res.statusCode == 200, items.length);
    return (true, items.length);
  } catch (_) {
    return (false, 0);
  }
}

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

/// Reactive notifier that loads, mutates, and persists the SRS item map.
///
/// On [build] it asynchronously hydrates state from [StorageService] and
/// subscribes to future storage updates. Every mutation through
/// [recordReview] is immediately flushed to storage via [_save].
class SrsReviewNotifier extends Notifier<Map<String, SrsItem>> {
  StorageService? _storage;
  // Pending writes — applied once storage is ready
  Map<String, SrsItem>? _pendingWrites;

  @override
  Map<String, SrsItem> build() {
    ref.watch(storageServiceProvider).whenData((s) {
      _storage = s;
      final raw = s.getJson(StorageService.kSrsItems);
      state = raw.map((k, v) => MapEntry(k, SrsItem.fromJson(v as Map<String, dynamic>)));
      // Apply any writes that arrived before storage was ready
      if (_pendingWrites != null) {
        state = {...state, ..._pendingWrites!};
        _pendingWrites = null;
        _flush();
      }
    });
    return {};
  }

  void _flush() {
    if (_storage == null) return;
    _storage!.setJson(StorageService.kSrsItems,
      state.map((k, v) => MapEntry(k, v.toJson())));
  }

  /// Merge [item] into state immediately, persist when storage ready.
  void _upsert(String itemId, SrsItem item) {
    if (_storage != null) {
      state = {...state, itemId: item};
      _flush();
    } else {
      // Storage not ready — buffer write
      _pendingWrites = {...?_pendingWrites, itemId: item};
      state = {...state, itemId: item}; // still update memory
    }
  }

  /// Record a review and update the SRS schedule for [itemId].
  ///
  /// Delegates to [SrsEngine.calculate] for the SM-2 algorithm, then
  /// computes [SrsItem.nextReviewAt]:
  /// - quality < 3 (wrong): immediate re-review (nextReviewAt = now)
  /// - quality >= 3 (correct): next review after [newInterval] days
  ///
  /// The updated item is merged into [state] and flushed to storage.
  void recordReview(String itemId, String type, int quality) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = state[itemId];
    final ef = existing?.ef ?? 2.5;
    final reps = existing?.reps ?? 0;
    final interval = existing?.interval ?? 1;
    final errors = (existing?.errors ?? 0) + (quality < 3 ? 1 : 0);
    final createdAt = existing?.createdAt ?? (quality < 3 ? now : 0);

    final (newEf, newReps, newInterval) = SrsEngine.calculate(ef, reps, interval, quality);
    // Wrong answers due immediately, correct answers follow SM-2 schedule
    final nextReviewAt = quality < 3
        ? now  // immediate review for wrong answers
        : now + Duration(days: newInterval).inMilliseconds;

    _upsert(itemId, SrsItem(
      itemId: itemId, type: type,
      ef: newEf, reps: newReps, interval: newInterval,
      nextReviewAt: nextReviewAt, errors: errors,
      createdAt: createdAt, lastReviewedAt: now,
    ));
  }
}
