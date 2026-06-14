import 'package:flutter/services.dart';

/// 触觉反馈包装 — 轻/中/重 触觉 + 系统音效。
///
/// 统一项目内所有触觉反馈的调用入口，便于全局调优振感强度与时长。
/// - [lightTap] 轻柔反馈，用于普通点击、正确答案等。
/// - [mediumTap] 中等反馈，用于切牌、弃牌等操作。
/// - [heavyTap] 强烈反馈，用于错误提示等需要引起注意的场景。
/// - [correctAnswer] / [wrongAnswer] / [discardSlash] 为语义化封装，
///   方便调用方按游戏事件触发对应振感，无需关心底层力度选择。
class HapticService {
  /// 轻柔触觉反馈，用于普通点击、正确答案等轻量交互。
  static void lightTap() => HapticFeedback.lightImpact();

  /// 中等触觉反馈，用于切牌、弃牌等中等强度操作。
  static void mediumTap() => HapticFeedback.mediumImpact();

  /// 强烈触觉反馈，用于错误提示等需要引起注意的场景。
  static void heavyTap() => HapticFeedback.heavyImpact();

  /// 正确答案触觉反馈（轻柔）。
  static void correctAnswer() => lightTap();

  /// 错误答案触觉反馈（连续两次强烈振感，间隔 100ms）。
  static void wrongAnswer() {
    heavyTap();
    Future.delayed(const Duration(milliseconds: 100), heavyTap);
  }

  /// 弃牌/切牌触觉反馈（中等）。
  static void discardSlash() => mediumTap();
}
