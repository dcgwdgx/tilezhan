/// SRS（Spaced Repetition System，间隔重复系统）的 Riverpod 状态管理层。
///
/// 本文件负责将 SRS 的完整复习生命周期暴露给 UI 层：
/// - [srsItemsProvider]：从本地存储异步加载所有 SRS 条目，并与内存中的实时状态合并。
/// - [dueItemsProvider]：筛选当前到期的待复习条目，按 [SrsItem.errorWeight] 降序排列。
/// - [srsNotifierProvider] / [SrsReviewNotifier]：记录用户复习结果，调用 SM-2 算法
///   重新计算调度参数，并立即持久化到本地存储。
///
/// 设计规范 §6.2 要求：条目按 errorWeight 优先排序，
/// 确保错误率最高的卡片优先出现在用户面前。
/// 答错（quality < 3）的条目会被安排立即重新复习，
/// 答对的条目则按照标准 SM-2 间隔递增规则推进下一次复习时间。
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
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
    final data = jsonEncode(items.map((i) => i.toJson()).toList());
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
/// 合并两个数据源：
/// 1. [storageServiceProvider] 中持久化的条目（磁盘数据）。
/// 2. [srsNotifierProvider] 中内存态的条目（实时修改）。
///
/// 合并规则：notifier（内存/实时）覆盖 storage（磁盘/持久化），
/// 确保刚完成的复习结果（如进入 graveyard）立即可见，
/// 无需等待下一次存储同步周期。
///
/// 返回类型为 [Map<String, SrsItem>]，key 为条目的唯一标识符。
final srsItemsProvider = Provider<Map<String, SrsItem>>((ref) {
  // 监听 notifier 以获取内存中的实时更新
  final notifierState = ref.watch(srsNotifierProvider);
  // 同时加载持久化存储中的条目
  final storageAsync = ref.watch(storageServiceProvider);
  final stored = storageAsync.valueOrNull?.getJson(StorageService.kSrsItems) ?? {};
  // 将原始 JSON Map 反序列化为 SrsItem 对象
  final fromStorage = stored.map((k, v) => MapEntry(k, SrsItem.fromJson(v as Map<String, dynamic>)));
  // 合并：notifier（内存/实时）覆盖 storage（磁盘/持久化）
  return {...fromStorage, ...notifierState};
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
  return items.values
      .where((i) => i.nextReviewAt <= now)
      .toList()
    // 按错误权重降序排列（高错误率优先）
    ..sort((a, b) => b.errorWeight.compareTo(a.errorWeight));
});

/// SRS 复习操作的 [NotifierProvider]。
///
/// 通过 [SrsReviewNotifier] 提供对 SRS 条目 Map 的读写能力：
/// - 加载：从 [StorageService] 异步加载持久化数据。
/// - 更新：通过 [SrsReviewNotifier.recordReview] 记录复习结果，触发 SM-2 重新计算。
/// - 持久化：每次变更后立即写回 [StorageService]。
final srsNotifierProvider = NotifierProvider<SrsReviewNotifier, Map<String, SrsItem>>(SrsReviewNotifier.new);

/// 反应式 Notifier：管理 SRS 条目 Map 的加载、变更与持久化。
///
/// 生命周期：
/// 1. [build] 阶段：等待 [StorageService] 就绪后异步初始化状态，
///    并订阅后续存储更新。
/// 2. 运行时：通过 [recordReview] 接收用户复习反馈，
///    调用 [SrsEngine.calculate] 重算 SM-2 参数，
///    并立即通过 [_flush] 写回存储。
/// 3. 容错：若存储尚未就绪时收到写入请求，
///    先缓冲到 [_pendingWrites]，待存储就绪后再刷入。
class SrsReviewNotifier extends Notifier<Map<String, SrsItem>> {
  // 本地存储服务引用，在 build() 阶段异步注入
  StorageService? _storage;
  // 挂起的写入缓冲区：存储就绪前收到的变更暂存于此，待存储可用后一次性刷新
  Map<String, SrsItem>? _pendingWrites;

  /// 初始化 SRS 状态：从 [StorageService] 加载持久化条目。
  ///
  /// 此方法在 Provider 首次被监听时调用：
  /// - 等待 [storageServiceProvider] 数据就绪。
  /// - 读取存储中的 SRS 条目并反序列化为 [SrsItem] Map。
  /// - 若有挂起的写入（在存储就绪前已到达的变更），立即合并并刷新。
  /// - 返回空 Map 作为初始值（真实数据在异步回调中填充）。
  @override
  Map<String, SrsItem> build() {
    // 监听存储服务，数据就绪时触发异步初始化
    ref.watch(storageServiceProvider).whenData((s) {
      _storage = s;
      // 从存储读取原始 JSON 并反序列化为 SrsItem 对象
      final raw = s.getJson(StorageService.kSrsItems);
      state = raw.map((k, v) => MapEntry(k, SrsItem.fromJson(v as Map<String, dynamic>)));
      // 若存储就绪前有挂起的写入，立即合并并清理缓冲区
      if (_pendingWrites != null) {
        state = {...state, ..._pendingWrites!};
        _pendingWrites = null;
        _flush();
      }
    });
    return {}; // 初始空状态，异步完成后自动更新
  }

  // 将当前状态立即写回 [StorageService] 持久化。
  // 若存储尚未就绪（[_storage] 为 null），静默跳过。
  void _flush() {
    if (_storage == null) return;
    _storage!.setJson(StorageService.kSrsItems,
      state.map((k, v) => MapEntry(k, v.toJson()))); // 序列化后写入存储
  }

  // 将指定 [item] 合并到状态中并尝试持久化。
  //
  // 有两种路径：
  // - 存储已就绪：直接更新 state 并调用 [_flush] 持久化。
  // - 存储未就绪：先更新 state（UI 可立即看到），
  //   同时缓冲到 [_pendingWrites]，待存储就绪后统一刷入。
  void _upsert(String itemId, SrsItem item) {
    if (_storage != null) {
      // 存储就绪：直接写入并持久化
      state = {...state, itemId: item};
      _flush();
    } else {
      // 存储未就绪：缓冲写入，不丢失数据
      _pendingWrites = {...?_pendingWrites, itemId: item};
      state = {...state, itemId: item}; // 仍然更新内存，确保 UI 立即可见
    }
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
  /// 更新后的条目通过 [_upsert] 合并到 state 并持久化。
  void recordReview(String itemId, String type, int quality) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // 获取已有条目数据，无历史则使用 SM-2 默认初始值
    final existing = state[itemId];
    final ef = existing?.ef ?? 2.5;
    final reps = existing?.reps ?? 0;
    final interval = existing?.interval ?? 1;
    // 答错时 errors +1
    final errors = (existing?.errors ?? 0) + (quality < 3 ? 1 : 0);
    // 首次创建时记录 createdAt；若答错且无历史则用当前时间
    final createdAt = existing?.createdAt ?? (quality < 3 ? now : 0);

    // 调用 SM-2 引擎计算新的调度参数
    final (newEf, newReps, newInterval) = SrsEngine.calculate(ef, reps, interval, quality);
    // 答错：立即重新复习；答对：按新间隔天数安排下次复习
    final nextReviewAt = quality < 3
        ? now  // 答错：立即安排重新复习
        : now + Duration(days: newInterval).inMilliseconds; // 答对：按间隔递进

    // 合并更新后的条目并持久化
    _upsert(itemId, SrsItem(
      itemId: itemId, type: type,
      ef: newEf, reps: newReps, interval: newInterval,
      nextReviewAt: nextReviewAt, errors: errors,
      createdAt: createdAt, lastReviewedAt: now,
    ));
  }
}
