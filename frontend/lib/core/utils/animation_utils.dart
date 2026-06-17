/// 动画工具集 — 贝塞尔曲线、缓动函数、精灵帧以及测试安全的动画辅助方法。
///
/// 在 Flutter 测试环境中，所有返回 [Duration] 的辅助方法均返回 [Duration.zero]，
/// 使得 widget 测试无需手动推进时间即可瞬时完成。在生产环境中，时长会乘以一个可
/// 配置的 [speedFactor]（0.0–1.0），调用方可以借此实现用户可调的动画速度偏好。
///
/// Animation utilities — Bezier curves, easing, sprite-sheet frames, and
/// test-safe animation helpers.
///
/// All duration-producing helpers return [Duration.zero] in the Flutter test
/// environment so that widget tests complete instantly without manual ticking.
/// In production, durations are scaled by a configurable `speedFactor`
/// (0.0–1.0) that lets the caller implement user-facing speed preferences.
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// 判断当前进程是否运行在 Flutter 测试环境中。
///
/// 通过检测 `FLUTTER_TEST` 环境变量来判断 —— 当用户执行 `flutter test` 或
/// `flutter run --test` 时，Flutter 框架会自动注入该变量。在测试环境中，
/// 所有动画时长会被置零以加速测试执行。
///
/// True when the process is running inside a Flutter test.
///
/// Checks for the `FLUTTER_TEST` environment variable that the framework
/// injects automatically when `flutter test` or `flutter run --test` is used.
bool get isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

/// 返回一个测试安全的 [Duration]，基于给定的毫秒数 [ms] 和动画速度因子 [speedFactor]。
///
/// 行为规则：
/// * 在测试环境中，始终返回 [Duration.zero]，跳过所有动画等待。
/// * 在生产环境中，实际时长为 `ms * speedFactor` 毫秒。其中 [speedFactor] 会被
///   钳制在 `[0.0, 1.0]` 区间内：0.0 表示动画瞬时完成（返回 [Duration.zero]），
///   1.0 表示动画以原始速度播放（返回完整的 `ms` 毫秒）。
///
/// 使用场景：任何需要通过 `speedFactor` 统一控制动画播放速度的地方，例如用户
/// 在设置中选择"慢速/正常/快速"动画偏好时。
///
/// Returns a test-safe [Duration] from the given [ms] and [speedFactor].
///
/// * In a test environment the result is always [Duration.zero].
/// * Otherwise the duration is `ms * speedFactor` milliseconds, where
///   [speedFactor] is clamped to the range `[0.0, 1.0]`. A factor of 0.0
///   yields [Duration.zero]; a factor of 1.0 yields the full `ms`.
Duration safeAnimDuration(int ms, double speedFactor) {
  // 测试环境下直接返回零时长，跳过所有动画
  if (isTestEnvironment) return Duration.zero;
  // 将速度因子钳制到合法区间，防止调用方传入越界值导致异常行为
  final s = speedFactor.clamp(0.0, 1.0);
  // 速度为 0 等同于关闭动画，返回零时长
  if (s == 0.0) return Duration.zero;
  // 按速度因子缩放并四舍五入到最接近的整数毫秒
  return Duration(milliseconds: (ms * s).round());
}

/// 创建一个 [AnimationController]，其时长在测试环境中自动归零，在生产环境中
/// 按 [speed]（即 speedFactor）缩放。
///
/// 这是对 [safeAnimDuration] 的便捷封装 —— 先通过 [safeAnimDuration] 计算出
/// 安全的 [Duration]，再将其作为 `duration` 参数传入 [AnimationController]
/// 构造函数。具体缩放语义请参见 [safeAnimDuration] 的文档。
///
/// 参数说明：
/// * [vsync]：Ticker 提供者，通常传 `this`（当调用方 mixin 了
///   `SingleTickerProviderStateMixin` 或 `TickerProviderStateMixin` 时）。
/// * [ms]：动画原始时长，单位为毫秒。
/// * [speed]：动画速度因子，范围 [0.0, 1.0]，含义与 [safeAnimDuration] 的
///   `speedFactor` 完全相同。
///
/// Creates an [AnimationController] whose duration is automatically
/// shortened to zero in tests and scaled by [speed] in production.
///
/// Convenience wrapper around [safeAnimDuration]; see that function for the
/// precise scaling semantics.
AnimationController safeController(TickerProvider vsync, int ms, double speed) {
  return AnimationController(
    vsync: vsync,
    duration: safeAnimDuration(ms, speed),
  );
}
