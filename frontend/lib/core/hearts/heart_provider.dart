/// 体力/每日挑战/战绩/促销 的 Riverpod 状态管理层。
///
/// 本文件是 [HeartService] 与 UI 层之间的桥梁，负责：
/// - 将 HeartService 单例暴露为 Riverpod Provider，统一生命周期管理
/// - 将体力、连斩、每日挑战等业务数据转换为可响应式消费的 Provider
/// - 组合 IAP 付费状态决定用户权限（免费 vs 付费用户的差异化逻辑）
///
/// 架构位置：属于 Core 层的状态管理模块，UI 层通过
/// `ref.watch(xxxProvider)` 订阅数据变化，无需直接操作 HeartService。
///
/// 关键 Provider 一览：
/// - [heartServiceProvider] — 全局单例 + 生命周期
/// - [heartsRemainingProvider] — 60s 轮询体力
/// - [canPlayProvider] — 能否开始游戏的门禁
/// - [dailyChallengeRemainingProvider] — 每日挑战剩余次数
/// - [battleReportProvider] — 当前会话战绩快照
/// - [showComboPromoProvider] — 10 连斩促销触发器
///
/// 依赖：[HeartService]（同级 heart_service.dart）、
/// [isPremiumProvider]（iap/iap_provider.dart）。

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'heart_service.dart';
import '../iap/iap_provider.dart';

// =============================================================================
//  第 1 区：体力 & 每日挑战
//  管理用户进行游戏的"燃料"——免费用户依赖体力/每日限额，
//  付费用户绕过所有限制。
// =============================================================================

/// 全局 [HeartService] 单例 Provider。
///
/// 职责：
/// - 创建 HeartService 单例并调用 [HeartService.init]，完成每日重置检查
/// - 当 Provider 被 Riverpod 销毁时，通过 [ref.onDispose] 自动释放
///   HeartService 占用的定时器等资源，防止内存泄漏
///
/// 这是整个体力模块的根 Provider，所有其他 Provider 都通过
/// `ref.watch(heartServiceProvider)` 获取对 HeartService 的引用。
///
/// 返回：生命周期受 Riverpod 管理的 HeartService 实例。
final heartServiceProvider = Provider<HeartService>((ref) {
  final svc = HeartService();
  svc.init();
  ref.onDispose(svc.dispose);
  return svc;
});

/// 每秒刷新一次的剩余心数流。
///
/// 使用 [StreamProvider] 包装一个 60 秒周期的定时流，每次事件触发时
/// 从 HeartService 拉取最新体力值。UI 层订阅此 Provider 后，
/// 体力数值变化会自动刷新，无需手动轮询。
///
/// 为什么用 [asBroadcastStream]：
/// - 多个 Widget 可能同时订阅该 Provider，broadcast 允许多监听者
/// - 默认单订阅流在 Riverpod 中会导致第二个订阅者抛出 StateError
///
/// 返回值类型：`AsyncValue<int>`，UI 通过 `.when()` 处理 loading/data/error。
final heartsRemainingProvider = StreamProvider<int>((ref) {
  final svc = ref.watch(heartServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 60), (i) => svc.hearts,
  ).asBroadcastStream();
});

/// 用户当前是否可以开始新游戏。
///
/// 逻辑：
/// - 付费用户（Premium）：始终返回 `true`，不受体力/每日次数限制
/// - 免费用户：委托 [HeartService.hasHearts] 判断，检查剩余心数 > 0
///   且每日挑战次数未耗尽
///
/// 典型用法：游戏入口按钮通过 `ref.watch(canPlayProvider)` 控制
/// 灰度状态与点击行为。
///
/// 返回值：`true` 表示可以进入游戏，`false` 表示该按钮应置灰并提示原因。
final canPlayProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  if (isPremium) return true;
  return ref.watch(heartServiceProvider).hasHearts;
});

/// 今日剩余免费挑战次数（每日 00:00 重置）。
///
/// 数据来源：[HeartService.dailyChallengeRemaining]，
/// 免费用户的额度，付费用户此值无意义（Premium 绕过限制）。
/// UI 可用于展示"今日剩余 X 次"提示或在耗尽时引导付费。
///
/// 返回值：剩余次数，最小为 0。
final dailyChallengeRemainingProvider = Provider<int>((ref) {
  return ref.watch(heartServiceProvider).dailyChallengeRemaining;
});

// =============================================================================
//  第 2 区：战绩报告
//  将 HeartService 中累计的战绩数据投影为不可变快照，
//  供结算弹窗和安全区域展示。
// =============================================================================

/// 单次会话的战绩快照（不可变值对象）。
///
/// 由 [battleReportProvider] 在每次重建时从 HeartService 拉取
/// 最新字段组装，数据每日自动重置。
///
/// 设计意图：
/// - 不可变（所有字段为 final）——避免 UI 意外修改服务端数据
/// - 提供计算属性 [total] 和 [accuracy] 作为便捷 UI 数据源
/// - 通过 const 构造函数支持高效重建
class BattleReport {
  /// 答对题数。
  final int correct;

  /// 答错题数。
  final int wrong;

  /// 本会话内最高连击数。
  final int maxCombo;

  /// 快照时剩余心数（用于结算界面展示）。
  final int heartsRemaining;

  /// 创建战绩快照。
  ///
  /// 所有字段必填，使用命名参数 + required 保证编译期安全。
  const BattleReport({
    required this.correct,
    required this.wrong,
    required this.maxCombo,
    required this.heartsRemaining,
  });

  /// 总答题数 = [correct] + [wrong]。
  int get total => correct + wrong;

  /// 正确率 = [correct] / [total]。
  ///
  /// 当 [total] == 0（未答题）时返回 0.0，避免除以零。
  double get accuracy => total == 0 ? 0 : correct / total;
}

/// 当前会话战绩的实时快照 Provider。
///
/// 数据源：[HeartService] 的 correct / wrong / maxCombo / hearts 字段。
/// 每次 Provider 被重新求值时都会生成新的 [BattleReport] 实例，
/// 确保 UI 看到的始终是最新数据。
///
/// 注意：结算界面的最终值应在弹窗打开时捕获快照并保持，
/// 避免弹窗显示期间数值继续变化。
///
/// 返回值：[BattleReport] 不可变实例。
final battleReportProvider = Provider<BattleReport>((ref) {
  final svc = ref.watch(heartServiceProvider);
  return BattleReport(
    correct: svc.correct,
    wrong: svc.wrong,
    maxCombo: svc.maxCombo,
    heartsRemaining: svc.hearts,
  );
});

// =============================================================================
//  第 3 区：连斩促销（10 连斩 → 付费弹窗）
//  当免费用户达成 10 连斩时触发促销入口，利用"正向反馈瞬间"
//  最大化付费转化率。付费用户不显示此促销。
// =============================================================================

/// 全时段跨会话累计连斩数。
///
/// 与 [battleReportProvider] 中的会话级 [BattleReport.maxCombo] 不同，
/// 此值为持久化的全历史最高连击记录，存储在 SharedPreferences 中，
/// 跨会话保持（每日重置不会清零）。
///
/// 用途：驱动 10 连斩促销逻辑的阈值判断依据。
///
/// 返回值：历史最高连斩数，默认 0。
final allTimeComboProvider = Provider<int>((ref) {
  return ref.watch(heartServiceProvider).allTimeCombo;
});

/// 是否应向当前用户展示"10 连斩促销"入口。
///
/// 触发条件（全部满足）：
/// 1. 用户是**免费用户** — [isPremiumProvider] 为 false
/// 2. 全时段连斩数 ≥ 10 — [HeartService.allTimeCombo]
///
/// 为什么只对免费用户显示：
/// - 付费用户已购买 Premium，展示降级/重复购买提示属无效信息
/// - 促销目标是转化免费用户为付费用户
///
/// 为什么在 10 连斩时触发：
/// - 10 连斩是用户"状态巅峰"时刻，成就感与参与感最强
/// - 行为经济学中"峰终定律"——在正向峰值时提供付费入口，
///   转化率远高于随机时机
///
/// 返回值：`true` 时 UI 应展示促销 Banner 或弹窗入口。
final showComboPromoProvider = Provider<bool>((ref) {
  final svc = ref.watch(heartServiceProvider);
  final isPremium = ref.watch(isPremiumProvider);
  if (isPremium) return false;
  return svc.allTimeCombo >= 10;
});
