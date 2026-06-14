/// 体力/每日挑战/战绩/促销的 Riverpod 状态管理。
///
/// 所有 Provider 基于 [HeartService] 单例，UI 通过 Riverpod 自动响应数据变化。

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'heart_service.dart';
import '../iap/iap_provider.dart';

// ---- 体力 & 每日挑战 ----

/// 全局 HeartService 单例（初始化时检查每日重置）。
final heartServiceProvider = Provider<HeartService>((ref) {
  final svc = HeartService();
  svc.init();
  ref.onDispose(svc.dispose);
  return svc;
});

/// 每 60 秒刷新一次剩余心数（UI 自动感知）。
final heartsRemainingProvider = StreamProvider<int>((ref) {
  final svc = ref.watch(heartServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 60), (i) => svc.hearts,
  ).asBroadcastStream();
});

/// 用户能否继续游戏：付费用户无限，免费用户需有剩余心数。
final canPlayProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  if (isPremium) return true;
  return ref.watch(heartServiceProvider).hasHearts;
});

/// 今日剩余免费挑战次数。
final dailyChallengeRemainingProvider = Provider<int>((ref) {
  return ref.watch(heartServiceProvider).dailyChallengeRemaining;
});

// ---- 战绩报告 ----

/// 持久化的战绩数据，费时作为弹窗输入。
class BattleReport {
  final int correct;
  final int wrong;
  final int maxCombo;
  final int heartsRemaining;

  const BattleReport({
    required this.correct,
    required this.wrong,
    required this.maxCombo,
    required this.heartsRemaining,
  });

  int get total => correct + wrong;
  double get accuracy => total == 0 ? 0 : correct / total;
}

/// 当前会话的战绩快照（每日重置）。
final battleReportProvider = Provider<BattleReport>((ref) {
  final svc = ref.watch(heartServiceProvider);
  return BattleReport(
    correct: svc.correct,
    wrong: svc.wrong,
    maxCombo: svc.maxCombo,
    heartsRemaining: svc.hearts,
  );
});

// ---- 组合促销（10 连斩）----

/// 全时跨会话连斩数。
final allTimeComboProvider = Provider<int>((ref) {
  return ref.watch(heartServiceProvider).allTimeCombo;
});

/// 是否触发 10 连斩促销（仅免费用户，≥10 连时显示）。
final showComboPromoProvider = Provider<bool>((ref) {
  final svc = ref.watch(heartServiceProvider);
  final isPremium = ref.watch(isPremiumProvider);
  if (isPremium) return false;
  return svc.allTimeCombo >= 10;
});
