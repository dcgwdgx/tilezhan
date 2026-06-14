/// 动画速度偏好 Provider。
///
/// 提供全局动画速度因子，供各组件读取以调整动画播放速率。
/// 存储为 [StateProvider<double>]，使用者通过 `ref.watch` 读取，
/// 或通过 `ref.read` + `update((_) => newValue)` 写入新值。
///
/// 速度常量：
/// - `1.0` — 完整速度（新手）
/// - `0.2` — 快速（高手）
/// - `0.0` — 关闭动画
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局动画速度因子。
///
/// 默认值为 [1.0]（完整速度）。
/// 1.0 = full (beginner), 0.2 = fast (expert), 0.0 = off
final animationSpeedProvider = StateProvider<double>((ref) => 1.0);
