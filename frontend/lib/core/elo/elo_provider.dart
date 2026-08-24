/// 本地 ELO 评分管理 — Riverpod StateNotifier + StorageService 持久化。
///
/// 管理玩家的本地 ELO 评分，在每次游戏结束后按公式更新，
/// 并通过 [StorageService] 持久化。上报到后端排行榜由
/// [LeaderboardService] 负责。
///
/// ## ELO 公式
///
/// ```
/// base 800 + correct × 10 - wrong × 5 - skip × 3
/// 钳位范围: [0, 3000]
/// ```
///
/// ## 使用示例
///
/// ```dart
/// // 读当前 ELO
/// final elo = ref.watch(eloProvider);
///
/// // 记录游戏结果
/// ref.read(eloProvider.notifier).recordResult(isCorrect: true, isSkip: false);
/// ```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../providers/storage_provider.dart';

/// 全局 ELO 评分状态提供者。
///
/// 自动释放以节省内存。初始化时从 [StorageService.kElo] 读取已有评分，
/// 若尚未记录则从基准 800 开始。
final eloProvider = StateNotifierProvider<EloNotifier, int>((ref) {
  final storageAsync = ref.watch(storageServiceProvider);
  final currentElo =
      storageAsync.valueOrNull?.getIntOrNull(StorageService.kElo) ?? 800;
  return EloNotifier(ref, currentElo);
});

/// 管理 ELO 评分的计算与持久化。
///
/// ## 数据流
///
/// ```
/// 游戏结束 → recordResult() → 更新内存 ELO → 持久化到 StorageService
///                                                    │
///                                                    ▼
///                                         LeaderboardService.reportScore()
/// ```
///
/// ELO 钳位在 [0, 3000] 防止极端异常值。跌至 0 以下不会继续扣减，
/// 达到 3000 以上不再增长。
class EloNotifier extends StateNotifier<int> {
  /// Riverpod Ref，用于访问 [StorageService] 进行持久化。
  final Ref _ref;

  EloNotifier(this._ref, int initialElo) : super(initialElo.clamp(0, 3000));

  /// 记录一次游戏结果并更新 ELO。
  ///
  /// [isCorrect] — 玩家回答正确（+10）
  /// [isSkip]    — 玩家选择跳过（-3）；非跳过且错误时（-5）
  ///
  /// 立即更新内存状态并异步持久化到 [StorageService]。
  void recordResult({required bool isCorrect, required bool isSkip}) {
    int delta;
    if (isCorrect) {
      delta = 10;
    } else if (isSkip) {
      delta = -3;
    } else {
      delta = -5;
    }
    state = (state + delta).clamp(0, 3000);
    _persist();
  }

  /// 将当前 ELO 评分异步写入 [StorageService]。
  ///
  /// 通过 [_ref] 读取 [storageServiceProvider] 获取存储实例。
  /// 写入失败时静默忽略——下次游戏结果会再次尝试持久化。
  void _persist() {
    final storage = _ref.read(storageServiceProvider).valueOrNull;
    if (storage != null) {
      storage.setInt(StorageService.kElo, state).catchError((e) {
        print('EloNotifier persist failed: $e');
      });
    }
  }
}
