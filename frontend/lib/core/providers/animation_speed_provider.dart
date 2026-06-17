/// 动画速度偏好 Provider — 全局动画播放速率控制中枢。
///
/// ## 职责
/// 本文件定义了一个全局的、可变的动画速度因子（`double`），供 TileZhan
/// 前端所有需要播放动画的组件统一读取。通过集中管理速度因子，用户可以
/// 一次性调整整个应用的动画快慢，而无需逐个组件设置。
///
/// ## 数据流
/// - **读取**：任意 Widget 通过 `ref.watch(animationSpeedProvider)` 订阅
///   速度变化，当速度被修改时 Riverpod 自动触发依赖 Widget 重建。
/// - **写入**：通过 `ref.read(animationSpeedProvider.notifier).update((_) =>
///   newValue)` 或 `ref.read(animationSpeedProvider.notifier).state = newValue`
///   更新当前速度因子。
///
/// ## Provider 类型选择
/// 选用 [StateProvider] 而非 [StateNotifierProvider] 或 [ChangeNotifierProvider]，
/// 原因：
/// - 状态仅为一个标量 `double`，无需复杂的状态类；
/// - 不需要附带业务逻辑（无校验、无异步、无副作用），`StateProvider` 的
///   `update` / `state=` 已足够覆盖所有写入场景；
/// - 保持依赖图轻量，减少不必要的 rebuild 范围。
///
/// ## 速度常量语义
/// | 值   | 含义                          | 典型使用者       |
/// |------|-------------------------------|------------------|
/// | 1.0  | 完整速度，每帧动画均播放      | 新手 / 默认      |
/// | 0.2  | 快速，动画时长缩短至 20%      | 高手 / 熟练玩家  |
/// | 0.0  | 关闭所有动画，瞬间到位        | 无障碍 / 性能模式|
///
/// ## 使用示例
/// ```dart
/// // 读取（响应式）
/// final speed = ref.watch(animationSpeedProvider);
/// final duration = baseDuration * speed;
///
/// // 写入（命令式）
/// ref.read(animationSpeedProvider.notifier).state = 0.2;
/// ```
///
/// ## 相关文件
/// - 消费者通常在 `lib/features/*/widgets/` 下的动画组件中引用本 Provider。
/// - 速度切换 UI 位于设置页面（如 `SettingsScreen`），由用户手动选择档位。
///
/// ## 注意事项
/// - `speed == 0.0` 时动画时长变为 0，务必确保组件能正确处理零时长
///   （例如 `Duration.zero` 下 `AnimationController` 直接跳到 `1.0`）。
/// - 该 Provider 不持久化；应用重启后恢复默认值 `1.0`。如需记住用户偏好，
///   应在设置页面配合 `SharedPreferences` 或本地数据库在启动时回写。
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局动画速度因子（不可为负）。
///
/// ## 概述
/// 一个顶层 [StateProvider]<[double]>，持有当前全局动画播放速度因子。
/// 所有依赖动画时长的 Widget 均通过此 Provider 获取速度因子，然后将其
/// 乘以基础时长，实现统一调速。
///
/// ## 默认值
/// 默认值为 `1.0`，即"完整速度 / 新手模式"，保证首次安装用户看到完整动画。
///
/// ## 取值范围（约定，非强制校验）
/// - `1.0` — 完整速度（新手），动画以原始设计时长播放；
/// - `0.2` — 快速（高手），动画时长缩短为原来的 1/5；
/// - `0.0` — 关闭动画，所有过渡瞬间完成。
///
/// 虽然 `StateProvider<double>` 不限制输入范围，但消费者应假定
/// 速度因子在 `[0.0, 1.0]` 闭区间内。超出此范围的值行为未定义，
/// 可能造成动画反向播放（负值）或慢于原始设计（>1.0）。
///
/// ## 线程安全
/// Riverpod 保证状态更新在 Dart 单线程模型下天然安全，无需额外同步。
///
/// ## 测试
/// 单元测试可直接创建 `ProviderContainer` 并读写此 Provider：
/// ```dart
/// final container = ProviderContainer();
/// expect(container.read(animationSpeedProvider), 1.0);
/// container.read(animationSpeedProvider.notifier).state = 0.2;
/// expect(container.read(animationSpeedProvider), 0.2);
/// ```
final animationSpeedProvider = StateProvider<double>((ref) => 1.0);
