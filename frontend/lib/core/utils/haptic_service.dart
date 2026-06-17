/// 触觉反馈统一服务 — 轻/中/重三级振感 + 语义化游戏事件反馈。
///
/// ## 职责
/// 封装 Flutter [HapticFeedback] 底层调用，为项目中所有需要触觉反馈的
/// 交互场景提供一套稳定、语义化的静态方法入口。调用方无需关心 `HapticFeedback`
/// 的 API 细节，也无需在各处硬编码 `Duration` 或力度选择逻辑。
///
/// ## 设计决策
/// - **仅有静态方法**：服务无状态，无需实例化，直接类名调用即可。
/// - **三级力度映射**：将 Android/iOS 原生 `lightImpact` / `mediumImpact` /
///   `heavyImpact` 三个档位映射到游戏语义（确认/操作/警告），保证跨平台一致体验。
/// - **语义化封装层**：`correctAnswer` / `wrongAnswer` / `discardSlash` 是上层的
///   "业务包装"，内部组合底层力度方法，调用方只需"告诉服务发生了什么事件"，
///   不用思考该用什么力度。未来如需统一调整力度或振感时长，只需修改此处。
///
/// ## 使用示例
/// ```dart
/// // 直接使用力度级别
/// HapticService.lightTap();   // 普通点击
/// HapticService.mediumTap();  // 切牌确认
/// HapticService.heavyTap();   // 严重错误
///
/// // 使用语义化方法（推荐）
/// HapticService.correctAnswer();  // 答对
/// HapticService.wrongAnswer();    // 答错（两次重振）
/// HapticService.discardSlash();   // 弃牌/切牌
/// ```
///
/// ## 平台兼容性
/// - **Android**: 映射到 `HapticFeedbackConstants` 的 `KEYCODE_STANDARD_*` 系列常量，
///   需要设备支持触觉引擎（大多数现代设备支持）。
/// - **iOS**: 映射到 `UIImpactFeedbackGenerator` 的不同 `UIImpactFeedbackStyle`，
///   iPhone 7 及以上机型硬件支持；旧设备静默降级，不会崩溃。
/// - **Web/Desktop**: Flutter 的 `HapticFeedback` 在这些平台上为 no-op
///   （静默无效果），因此本服务不会导致异常，只是没有实际振感。
///
/// ## 注意事项
/// - 所有方法均为同步触发（`void` 返回），不会等待振感结束。
/// - `wrongAnswer()` 内部使用 `Future.delayed` 调度第二次振感，但不返回 Future，
///   调用方无需 `await`。如果需要在振感结束后执行逻辑，应考虑异步版本或回调。
/// - 避免在极短时间内高频调用（如每帧触发），否则可能导致振感叠加为持续震动，
///   用户体验变差。建议单次交互不超过 2 次振感调用。
import 'package:flutter/services.dart';

/// 触觉反馈服务 — 统一项目内所有触觉反馈的调用入口。
///
/// 提供两级调用抽象：
/// 1. **力度原语** — [lightTap] / [mediumTap] / [heavyTap]，直接映射原生三级振感。
/// 2. **语义化事件** — [correctAnswer] / [wrongAnswer] / [discardSlash]，按游戏
///    事件封装力度逻辑，未来如需全局调优振感强度或时长，只需修改本类。
///
/// 所有方法均为 `static`，无需创建实例。
class HapticService {
  /// 轻柔触觉反馈，映射到原生 `lightImpact`。
  ///
  /// **适用场景**：
  /// - 普通按钮点击（非关键操作）
  /// - 正确答案确认（轻量正面反馈）
  /// - 页面切换、tab 点击等日常交互
  /// - 滑动选择、微调控件等连续操作的每一步
  ///
  /// **注意**：此力度最轻，在部分 Android 设备上几乎不可感知，
  /// 不要用于需要明确引起用户注意的场景。
  static void lightTap() => HapticFeedback.lightImpact();

  /// 中等触觉反馈，映射到原生 `mediumImpact`。
  ///
  /// **适用场景**：
  /// - 切牌操作确认（滑动切牌触发）
  /// - 弃牌/移除操作（中等强度提示）
  /// - 牌面翻转、抽牌等有明显物理隐喻的操作
  /// - 设置项开关切换（有状态变更的中等操作）
  ///
  /// 力度介于 light 和 heavy 之间，适合"操作已确认"但非紧急的反馈。
  static void mediumTap() => HapticFeedback.mediumImpact();

  /// 强烈触觉反馈，映射到原生 `heavyImpact`。
  ///
  /// **适用场景**：
  /// - 错误答案提示（警告用户注意）
  /// - 操作失败、非法输入等需要立即纠正的场景
  /// - 重要操作不可逆前的最后确认（如删除账号、清除所有数据）
  ///
  /// **注意**：此力度最强，不应频繁使用，否则会引起用户烦躁。
  /// 通常每 2 秒内最多触发一次为宜。
  static void heavyTap() => HapticFeedback.heavyImpact();

  /// 正确答案触觉反馈 — 语义化封装，内部使用轻柔力度。
  ///
  /// 调用方只需关心"用户答对了"这一业务事件，无需思考该用什么力度。
  /// 当前映射到 [lightTap]，因为答对是正面、轻松的反馈，强振感会适得其反。
  static void correctAnswer() => lightTap();

  /// 错误答案触觉反馈 — 连续两次强烈振感，间隔 100ms。
  ///
  /// 设计意图：单次重振容易被忽略，两次连续重振产生"咚咚"的警告感，
  /// 能有效吸引用户注意，又不至于像三次以上那样过度侵扰。
  ///
  /// **实现细节**：
  /// - 第一次 [heavyTap] 立即触发（同步）；
  /// - 第二次 [heavyTap] 通过 [Future.delayed] 在 100ms 后异步调度，
  ///   调用方无需 `await`；
  /// - 如果用户快速连续答错，可能出现多个延迟回调排队，属正常行为 —
  ///   每次错误独立产生两次振感，叠加后形成更密集的警告模式，符合预期。
  static void wrongAnswer() {
    // 第一次重振：立即触发，让用户立刻感知到"出错了"。
    heavyTap();
    // 第二次重振：延迟 100ms，产生"咚咚"双重警告感。
    // 不使用 await，调用方无需关心 Future 完成时机。
    Future.delayed(const Duration(milliseconds: 100), heavyTap);
  }

  /// 弃牌/切牌触觉反馈 — 语义化封装，内部使用中等力度。
  ///
  /// 切牌和弃牌都涉及"牌从手中滑出"的物理隐喻，中等力度正好模拟
  /// 牌面离开手指时的轻微阻力感。当前映射到 [mediumTap]。
  static void discardSlash() => mediumTap();
}
