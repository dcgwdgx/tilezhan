/// 全局音频与触觉反馈服务（Audio + Haptic Service）。
///
/// 负责管理游戏中所有音效播放和触觉振动反馈。通过 [audioplayers] 播放 WAV 音效文件，
/// 并通过 [HapticService] 和 Flutter 原生 [HapticFeedback] 在支持的设备上触发触觉振动。
///
/// 核心职责：
/// - 播放 UI 交互音效（点击、正误、完成、弃牌等）
/// - 播放中国麻将牌面的 TTS 语音朗读
/// - 触发对应的触觉振动反馈，增强操作感知
///
/// 提供全局开关 [_enabled]，用户可通过 [setEnabled] 控制是否启用音效和触觉反馈，
/// 所有公开方法均会在执行前检查该标志位。
///
/// 架构位置：属于 `core/utils` 层——工具服务层，被 UI 层和游戏逻辑层共同调用，
/// 不依赖任何上层模块。
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'haptic_service.dart';

/// 游戏音效 + 触觉反馈管理器。
///
/// 提供静态方法集合，无需实例化即可使用。所有公开方法均在调用前检查 [_enabled] 标志，
/// 当用户关闭音效时静默跳过所有播放和振动操作。
///
/// 设计要点：
/// - 单例模式：所有字段和方法均为静态，全局仅维护一个 [AudioPlayer] 实例
/// - 失败安全：所有音频播放和触觉调用均被 try-catch 包裹，确保异常不会导致应用崩溃
/// - 分层触觉：[HapticService] 提供语义化封装，[HapticFeedback] 提供原生底层能力
class AudioService {
  /// 全局唯一的音频播放器实例，复用避免重复创建资源开销。
  static final _player = AudioPlayer();

  /// 全局音效启用标志，默认开启。
  /// 由 [setEnabled] 修改，由 [isEnabled] 暴露给外部查询。
  static bool _enabled = true;

  /// 设置音效与触觉反馈的全局开关。
  ///
  /// [v] 为 `true` 时启用所有音效和触觉，为 `false` 时静默关闭。
  /// 调用后所有后续的 [playTap]、[playCorrect] 等方法将立即受此开关控制。
  static void setEnabled(bool v) => _enabled = v;

  /// 返回当前音效与触觉反馈是否已启用。
  ///
  /// 外部模块（如设置页面）可通过此 getter 查询当前音效状态以渲染正确的 UI 状态。
  static bool get isEnabled => _enabled;

  /// 播放轻触音效 + 轻触振动：用于 UI 按钮点击等轻量操作。
  ///
  /// 音效：播放 `tap.wav`
  /// 触觉：调用 [HapticService.lightTap]（轻量单击反馈）
  static void playTap() {
    if (!_enabled) return;
    _playSfx('tap.wav');
    try { HapticService.lightTap(); } catch (_) {}
  }

  /// 播放正确音效 + 庆祝振动：用于用户答对题目时的正向反馈。
  ///
  /// 音效：播放 `correct.wav`
  /// 触觉：先调用 [HapticService.correctAnswer]（语义化正确反馈），
  ///       再触发原生 [HapticFeedback.heavyImpact]（高强度振动增强庆祝感）
  static void playCorrect() {
    if (!_enabled) return;
    _playSfx('correct.wav');
    try { HapticService.correctAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// 播放错误音效 + 双重脉冲振动：用于用户答错题目时的警示反馈。
  ///
  /// 音效：播放 `wrong.wav`
  /// 触觉：立即触发一次语义化错误反馈 + 一次高强度振动，
  ///       延迟 80ms 后再触发第二次高强度振动，形成"双重脉冲"警示效果。
  ///       这种双脉冲模式能显著提升错误感知，用户无需看屏幕即可感知答错。
  static void playWrong() {
    if (!_enabled) return;
    _playSfx('wrong.wav');
    try { HapticService.wrongAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
    // 延迟 80ms 后触发第二次高强度振动，形成双重脉冲警示效果
    Future.delayed(const Duration(milliseconds: 80), () {
      try { HapticFeedback.heavyImpact(); } catch (_) {}
    });
  }

  /// 播放完成音效 + 完成振动：用于游戏/关卡/测验完成时的庆祝反馈。
  ///
  /// 音效：播放 `complete.wav`（完成庆祝配乐）
  /// 触觉：调用 [HapticService.heavyTap] + [HapticFeedback.heavyImpact]，
  ///       双重高强度振动营造强烈的完成仪式感
  static void playComplete() {
    if (!_enabled) return;
    _playSfx('complete.wav');
    try { HapticService.heavyTap(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// 播放弃牌/划除音效 + 中等振动：用于用户丢弃或划除牌面的操作。
  ///
  /// 音效：播放 `slash.wav`（划除/刀锋音效）
  /// 触觉：调用 [HapticService.discardSlash]（语义化弃牌反馈）+
  ///       [HapticFeedback.mediumImpact]（中等强度振动）
  static void playSlash() {
    if (!_enabled) return;
    _playSfx('slash.wav');
    try { HapticService.discardSlash(); } catch (_) {}
    try { HapticFeedback.mediumImpact(); } catch (_) {}
  }

  /// 播放中国麻将牌的 TTS 语音朗读。
  ///
  /// 根据牌的 ID 加载对应的预录制语音文件并播放。与 SFX 音效不同，
  /// 语音播放会先停止当前正在播放的音频（[AudioPlayer.stop]），
  /// 确保新的语音不会被旧音频干扰，适合连续点选牌面的场景。
  ///
  /// 参数 [tileId]：牌的标识符（如 `wan1`, `tong3`, `tiao7` 等），
  ///               对应 `assets/sounds/voice/` 目录下的 `{tileId}.wav` 文件。
  ///
  /// 返回值：返回 [Future<void>]，调用方可 await 等待语音播放完成。
  ///
  /// 降级策略：如果 WAV 语音文件播放失败（如文件缺失），
  ///           降级使用系统默认点击音效 [SystemSound.play]，保证体验不中断。
  static Future<void> playVoice(String tileId) async {
    if (!_enabled) return;
    try {
      // 先停止当前音频，避免与新的语音叠加混淆
      await _player.stop();
      await _player.play(AssetSource('sounds/voice/$tileId.wav'));
    } catch (_) {
      // 语音文件播放失败时，降级使用系统点击音效作为兜底
      try { SystemSound.play(SystemSoundType.click); } catch (_) {}
    }
  }

  // ============================================================
  //  内部实现（私有方法）
  // ============================================================

  /// 播放 `assets/sounds/` 目录下的 WAV 音效文件。
  ///
  /// 这是一个内部通用方法，所有公开的音效方法（[playTap]、[playCorrect] 等）
  /// 均通过此方法完成实际的音频播放。
  ///
  /// [filename]：音效文件名（不含路径前缀），如 `tap.wav`。
  ///             完整资源路径为 `assets/sounds/{filename}`。
  ///
  /// 安全设计：播放失败时静默吞掉异常，确保单个音效的加载失败不会导致应用崩溃
  ///           或影响后续音效的播放。
  static void _playSfx(String filename) {
    try {
      _player.play(AssetSource('sounds/$filename'));
    } catch (_) { /* 音效加载失败不应导致应用崩溃，静默忽略 */ }
  }
}
