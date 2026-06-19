/// App Store 评分引导服务。
///
/// 在用户连续答对 [kReviewComboThreshold] 题后请求系统评分弹窗。
/// 使用 `in_app_review` 包调用 iOS 原生 SKStoreReviewController。
/// 每个 App Store 版本每年最多弹 3 次（系统限制），触达率由 Apple
/// 控制，无法强制弹出。
///
/// 触发时机：何切或闪卡答对后检查连击数。
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// 触发评分请求所需的连续答对次数。
const kReviewComboThreshold = 5;

/// 最近一次请求评分的日期（ISO 日期部分），用于冷却限制。
/// 存储在 Hive `prefs` box 中，避免同一天反复请求。
const kLastReviewKey = 'last_review_date';

/// 尝试触发系统评分弹窗。
///
/// [combo] 当前连击数。
/// [lastReviewDate] 上次请求评分的日期（ISO 字符串），为空表示从未请求。
///
/// 仅在以下条件全部满足时才请求：
/// - combo >= [kReviewComboThreshold]
/// - 当天尚未请求过评分
/// - 非 Debug 模式（避免开发中误触）
///
/// 请求成功后更新 [lastReviewDate] 到今天。
void maybeRequestReview(int combo, String lastReviewDate) {
  if (combo < kReviewComboThreshold) return;
  if (kDebugMode) return; // 开发环境不弹评分

  final today = DateTime.now().toIso8601String().substring(0, 10);
  if (lastReviewDate == today) return;

  final review = InAppReview.instance;
  review.requestReview();

  // 更新最后请求日期（无论系统是否实际弹出对话框）
  // 注意：此方法无法写入 Hive，由调用方负责写入。
}
