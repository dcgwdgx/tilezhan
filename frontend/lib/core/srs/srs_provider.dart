// SRS（Spaced Repetition System，间隔重复系统）的 Riverpod 状态管理层。
//
// 本文件负责将 SRS 的完整复习生命周期暴露给 UI 层：
// - srsItemsProvider：从本地存储异步加载所有 SRS 条目，并与内存中的实时状态合并。
// - dueItemsProvider：筛选当前到期的待复习条目，按 errorWeight 降序排列。
// - srsNotifierProvider / SrsReviewNotifier：记录用户复习结果，调用 SM-2 算法
//   重新计算调度参数，并立即持久化到本地存储。
//
// 设计规范 §6.2 要求：条目按 errorWeight 优先排序，
// 确保错误率最高的卡片优先出现在用户面前。
// 答错（quality < 3）的条目会被安排立即重新复习，
// 答对的条目则按照标准 SM-2 间隔递增规则推进下一次复习时间。
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_service.dart';
import '../providers/storage_provider.dart';
import 'srs_engine.dart';
import 'srs_item.dart';

/// 将本地 SRS 数据序列化为 JSON 并同步到后端服务器。
///
/// 返回一个元组 (success, uploadedCount)：
/// - success：同步是否成功。
/// - uploadedCount：已上传的条目数量。
///
/// 注意：后端 API 已部署，但 HTTP 客户端（DioClient）尚未对接完成，
/// 当前仅执行 JSON 序列化，不实际发送网络请求。
/// 待 [DioClient] 集成后取消注释即可启用真实同步。
Future<(bool, int)> syncSrsToCloud(List<SrsItem> items) async {
  try {
    // 将所有条目序列化为 JSON 列表
    jsonEncode(items.map((i) => i.toJson()).toList());
    // TODO: 待 DioClient 对接后启用真实 HTTP POST
    // final res = await DioClient.instance.post(ApiEndpoints.srsSync, data: data);
    // return (res.statusCode == 200, items.length);
    return (true, items.length); // 当前仅模拟成功返回
  } catch (_) {
    return (false, 0); // 序列化或网络异常时返回失败
  }
}

/// 所有已知 SRS 条目的 [Provider]。
///
/// [SrsReviewNotifier] 统一负责安全加载磁盘数据、合并加载期间的
/// 内存操作，并立即暴露最新状态。本 Provider 只转发该单一事实源。
///
/// 返回类型为 [Map<String, SrsItem>]，key 为条目的唯一标识符。
final srsItemsProvider = Provider<Map<String, SrsItem>>((ref) {
  // Notifier 已负责安全解码磁盘数据及重放加载期间的内存事件。
  // 不在这里再次直接解码，避免一个损坏 sibling 使整个 Provider 抛错。
  // 保持旧 API 返回独立 Map 的语义，避免读方误改 notifier state。
  return {...ref.watch(srsNotifierProvider)};
});

/// 当前到期待复习的 SRS 条目列表。
///
/// 筛选逻辑：
/// - 从 [srsItemsProvider] 中取出所有条目。
/// - 仅保留 [SrsItem.nextReviewAt] <= 当前时间（已到期）的条目。
/// - 按 [SrsItem.errorWeight] 降序排列（设计规范 §6.2）。
///
/// 排序确保错误率最高的卡片排在最前面，用户优先攻克薄弱项。
final dueItemsProvider = Provider<List<SrsItem>>((ref) {
  final items = ref.watch(srsItemsProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  // 筛选已到期的条目
  return items.values.where((i) => i.nextReviewAt <= now).toList()
    // 按错误权重降序排列（高错误率优先）
    ..sort((a, b) => b.errorWeight.compareTo(a.errorWeight));
});

/// SRS 复习操作的 [NotifierProvider]。
///
/// 通过 [SrsReviewNotifier] 提供对 SRS 条目 Map 的读写能力：
/// - 加载：从 [StorageService] 异步加载持久化数据。
/// - 更新：通过 [SrsReviewNotifier.recordReview] 记录复习结果，触发 SM-2 重新计算。
/// - 持久化：每次变更后立即写回 [StorageService]。
final srsNotifierProvider =
    NotifierProvider<SrsReviewNotifier, Map<String, SrsItem>>(
        SrsReviewNotifier.new);

/// Injectable persistence boundary for the SRS JSON object.
///
/// Keeping raw JSON at this boundary lets the notifier isolate malformed
/// entries one by one instead of losing every valid sibling.
abstract interface class SrsStore {
  Map<String, dynamic> read();

  Future<void> write(Map<String, dynamic> value);
}

/// Production SRS persistence backed by [StorageService].
class StorageServiceSrsStore implements SrsStore {
  const StorageServiceSrsStore(this._storage);

  final StorageService _storage;

  @override
  Map<String, dynamic> read() => _storage.getJson(StorageService.kSrsItems);

  @override
  Future<void> write(Map<String, dynamic> value) async {
    // StorageService keeps its legacy best-effort API and swallows I/O errors.
    // Verify the completed write here so the SRS queue can retain/retry a
    // terminal dirty snapshot instead of reporting a false successful flush.
    final expected = jsonEncode(value);
    await _storage.setJson(StorageService.kSrsItems, value);
    final persisted = _storage.getJson(StorageService.kSrsItems);
    if (jsonEncode(persisted) != expected) {
      throw StateError('SRS storage verification failed');
    }
  }
}

/// Store provider kept separate so loading and write ordering can be tested
/// deterministically without touching the filesystem.
final srsStoreProvider = FutureProvider<SrsStore>((ref) async {
  final storage = await ref.watch(storageServiceProvider.future);
  return StorageServiceSrsStore(storage);
});

/// 反应式 Notifier：管理 SRS 条目 Map 的加载、变更与持久化。
///
/// 生命周期：
/// 1. [build] 阶段：等待 [SrsStore] 就绪后异步初始化状态。
/// 2. 运行时：通过 [recordReview] 接收用户复习反馈，
///    调用 [SrsEngine.calculate] 重算 SM-2 参数，
///    并将完整快照严格串行写回存储。
/// 3. 容错：存储就绪前的操作按发生顺序重放到磁盘状态上，
///    一个损坏条目也不会影响其他有效 sibling。
class SrsReviewNotifier extends Notifier<Map<String, SrsItem>> {
  SrsStore? _store;
  final List<_SrsMutation> _pendingMutations = [];
  Future<void> _writeQueue = Future<void>.value();
  Map<String, dynamic>? _pendingSnapshot;
  Object? _terminalWriteError;
  StackTrace? _terminalWriteStackTrace;
  bool _writePumpRunning = false;
  bool _persistenceEnabled = false;
  bool _disposed = false;

  /// 初始化 SRS 状态：从 [SrsStore] 加载持久化条目。
  ///
  /// 此方法在 Provider 首次被监听时调用：
  /// - 等待 [srsStoreProvider] 数据就绪。
  /// - 读取存储中的 SRS 条目并反序列化为 [SrsItem] Map。
  /// - 若有加载期间的操作，按发生顺序重放并串行刷新。
  /// - 返回空 Map 作为初始值（真实数据在异步回调中填充）。
  @override
  Map<String, SrsItem> build() {
    _persistenceEnabled = true;
    ref.onDispose(() => _disposed = true);
    ref.listen<AsyncValue<SrsStore>>(
      srsStoreProvider,
      (_, next) {
        next.whenData((store) {
          // An immediately available FutureProvider can notify while build is
          // still establishing state. Defer attachment, but never let the
          // untracked callback act after this notifier has been disposed.
          Future<void>.microtask(() {
            if (!_disposed) _attachStore(store);
          });
        });
      },
      fireImmediately: true,
    );
    return {};
  }

  /// Waits until storage is initialized and the write queue is stably empty.
  ///
  /// Mutations appended while this method is waiting are included. A terminal
  /// dirty snapshot is retried once; persistent failure is surfaced to the
  /// caller instead of being mistaken for a successful flush.
  Future<void> flush() async {
    // Existing tests and integrations subclass this notifier with a build-only
    // in-memory implementation. Preserve that public pattern: it has no
    // persistence lifecycle and flush is intentionally a no-op.
    if (!_persistenceEnabled || _disposed) return;
    if (_store == null) {
      final store = await ref.read(srsStoreProvider.future);
      if (_disposed) return;
      _attachStore(store);
    }

    var retriedTerminalSnapshot = false;
    while (!_disposed) {
      if (!_writePumpRunning && _pendingSnapshot != null) {
        if (_terminalWriteError != null) {
          if (retriedTerminalSnapshot) {
            _throwTerminalWriteError();
          }
          retriedTerminalSnapshot = true;
        }
        _startWritePump(retryTerminal: true);
      }

      final tail = _writeQueue;
      await tail;

      // A mutation can append a new pump while flush awaits the previous one.
      if (!identical(tail, _writeQueue) || _writePumpRunning) continue;
      if (_pendingSnapshot == null) return;
      if (_terminalWriteError != null && retriedTerminalSnapshot) {
        _throwTerminalWriteError();
      }
    }
  }

  void _apply(_SrsMutation mutation) {
    if (_persistenceEnabled && _store == null) {
      _pendingMutations.add(mutation);
    }
    state = mutation.applyTo(state);
    if (_persistenceEnabled && _store != null) _queueWrite();
  }

  /// Replaces only an item's content snapshot while preserving its schedule.
  ///
  /// This is used by schema/rules migrations. It must not count as a review or
  /// change EF, repetitions, intervals, errors, or review timestamps.
  void replaceContentPreservingSchedule(
    SrsItem fallbackItem,
    Map<String, dynamic> content,
  ) {
    _apply(
      _ReplaceSrsContent(
        fallbackItem: fallbackItem,
        content: Map<String, dynamic>.from(content),
      ),
    );
  }

  /// Removes an item whose stored snapshot can no longer be reconstructed.
  ///
  /// This is intentionally narrower than a general user-facing delete API:
  /// callers use it only after a versioned precision-review loader has proved
  /// that the item is unrecoverable. Keeping it due forever would trap both
  /// the review queue and the daily plan.
  void discardUnrecoverableItem(String itemId) {
    final normalized = itemId.trim();
    if (normalized.isEmpty) return;
    _apply(_DiscardSrsItem(normalized));
  }

  /// 记录用户对 [itemId] 的一次复习，并更新其 SM-2 调度参数。
  ///
  /// 参数：
  /// - [itemId]：被复习的条目唯一标识符。
  /// - [type]：条目类型（如"牌名"、"助记"等）。
  /// - [quality]：复习质量评分（0-5），来自用户的反馈。
  ///
  /// 调度逻辑（SM-2 算法）：
  /// - 委托 [SrsEngine.calculate] 计算新的 EF、reps、interval。
  /// - quality < 3（答错）：[nextReviewAt] = 当前时间（立即重新复习）。
  /// - quality >= 3（答对）：[nextReviewAt] = 当前时间 + [newInterval] 天。
  /// - 每次答错，[errors] 计数 +1，影响后续的 errorWeight 排序。
  ///
  /// 更新后的条目立即合并到 state 并排队持久化。
  void recordReview(
    String itemId,
    String type,
    int quality, {
    Map<String, dynamic>? content,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _apply(
      _RecordSrsReview(
        itemId: itemId,
        type: type,
        quality: quality,
        occurredAt: now,
        content: content == null ? null : Map<String, dynamic>.from(content),
      ),
    );
  }

  void _attachStore(SrsStore store) {
    if (_disposed || _store != null) return;
    _store = store;

    var loaded = _decodeSrsItems(store.read());
    final pending = List<_SrsMutation>.of(_pendingMutations);
    _pendingMutations.clear();
    for (final mutation in pending) {
      loaded = mutation.applyTo(loaded);
    }
    state = loaded;
    if (pending.isNotEmpty) _queueWrite();
  }

  void _queueWrite() {
    final store = _store;
    if (store == null || _disposed) return;
    // A complete newest snapshot supersedes any older snapshot that has not
    // started writing yet. At most one write is in flight and one is pending.
    _pendingSnapshot = _encodeSrsItems(state);
    _terminalWriteError = null;
    _terminalWriteStackTrace = null;
    _startWritePump();
  }

  void _startWritePump({bool retryTerminal = false}) {
    if (_disposed ||
        _store == null ||
        _writePumpRunning ||
        _pendingSnapshot == null ||
        (_terminalWriteError != null && !retryTerminal)) {
      return;
    }
    _writePumpRunning = true;
    _writeQueue = _drainWriteQueue();
  }

  Future<void> _drainWriteQueue() async {
    final store = _store!;
    try {
      while (!_disposed && _pendingSnapshot != null) {
        final snapshot = _pendingSnapshot!;
        _pendingSnapshot = null;
        try {
          await store.write(snapshot);
          _terminalWriteError = null;
          _terminalWriteStackTrace = null;
        } on Object catch (error, stackTrace) {
          _terminalWriteError = error;
          _terminalWriteStackTrace = stackTrace;
          if (_pendingSnapshot == null) {
            // No newer complete snapshot can supersede the failed one. Keep it
            // dirty so flush can retry it or report the persistent failure.
            _pendingSnapshot = snapshot;
            break;
          }
          // A newer complete snapshot is already pending. Continue directly;
          // its success persists every mutation included in the failed one.
        }
      }
    } finally {
      _writePumpRunning = false;
    }
  }

  Never _throwTerminalWriteError() {
    final error = _terminalWriteError!;
    Error.throwWithStackTrace(
      error,
      _terminalWriteStackTrace ?? StackTrace.current,
    );
  }
}

abstract interface class _SrsMutation {
  Map<String, SrsItem> applyTo(Map<String, SrsItem> items);
}

class _RecordSrsReview implements _SrsMutation {
  const _RecordSrsReview({
    required this.itemId,
    required this.type,
    required this.quality,
    required this.occurredAt,
    required this.content,
  });

  final String itemId;
  final String type;
  final int quality;
  final int occurredAt;
  final Map<String, dynamic>? content;

  @override
  Map<String, SrsItem> applyTo(Map<String, SrsItem> items) {
    final existing = items[itemId];
    final (newEf, newReps, newInterval) = SrsEngine.calculate(
      existing?.ef ?? 2.5,
      existing?.reps ?? 0,
      existing?.interval ?? 1,
      quality,
    );
    final nextReviewAt = quality < 3
        ? occurredAt
        : occurredAt + Duration(days: newInterval).inMilliseconds;
    final item = SrsItem(
      itemId: itemId,
      type: type,
      ef: newEf,
      reps: newReps,
      interval: newInterval,
      nextReviewAt: nextReviewAt,
      errors: (existing?.errors ?? 0) + (quality < 3 ? 1 : 0),
      createdAt: existing?.createdAt ?? occurredAt,
      lastReviewedAt: occurredAt,
      content: content ?? existing?.content,
    );
    return {...items, itemId: item};
  }
}

class _ReplaceSrsContent implements _SrsMutation {
  const _ReplaceSrsContent({
    required this.fallbackItem,
    required this.content,
  });

  final SrsItem fallbackItem;
  final Map<String, dynamic> content;

  @override
  Map<String, SrsItem> applyTo(Map<String, SrsItem> items) {
    final current = items[fallbackItem.itemId] ?? fallbackItem;
    return {
      ...items,
      current.itemId: current.copyWith(
        content: Map<String, dynamic>.from(content),
      ),
    };
  }
}

class _DiscardSrsItem implements _SrsMutation {
  const _DiscardSrsItem(this.itemId);

  final String itemId;

  @override
  Map<String, SrsItem> applyTo(Map<String, SrsItem> items) {
    if (!items.containsKey(itemId)) return items;
    return Map<String, SrsItem>.of(items)..remove(itemId);
  }
}

Map<String, SrsItem> _decodeSrsItems(Map<String, dynamic> raw) {
  final decoded = <String, SrsItem>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    try {
      final item = SrsItem.fromJson(Map<String, dynamic>.from(value));
      if (item.itemId != entry.key || !_isSaneSrsItem(item)) continue;
      decoded[entry.key] = item;
    } on Object {
      // One malformed item must not discard valid siblings.
    }
  }
  return decoded;
}

bool _isSaneSrsItem(SrsItem item) =>
    item.itemId.trim().isNotEmpty &&
    item.type.trim().isNotEmpty &&
    item.ef.isFinite &&
    item.ef >= 1.3 &&
    item.reps >= 0 &&
    item.interval >= 1 &&
    item.nextReviewAt >= 0 &&
    item.errors >= 0 &&
    item.createdAt >= 0 &&
    item.lastReviewedAt >= 0;

Map<String, dynamic> _encodeSrsItems(Map<String, SrsItem> items) =>
    items.map((itemId, item) => MapEntry(itemId, item.toJson()));
