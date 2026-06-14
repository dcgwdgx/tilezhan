/// 埋点 (Analytics) 服务 — 事件缓冲、批量上报与会话追踪。
///
/// 设计目标：
/// - 本地优先：开发环境打印到控制台，生产环境接入 Firebase / Amplitude。
/// - 事件缓冲：通过内存缓冲 [_buffer] 暂存事件，定期或手动 [flush] 批量上报。
/// - 轻量嵌入：所有追踪方法均为静态方法，无需实例化即可调用。
/// - 可测试性：提供 [reset] 方法还原默认状态，配合单元测试使用。
///
/// 使用示例：
/// ```dart
/// AnalyticsService.screen('HomePage');
/// AnalyticsService.answered('sima_yi', true);
/// AnalyticsService.levelUp(5);
/// ```
///
/// Per design spec: lib/core/analytics/analytics_service.dart
class AnalyticsService {
  static final List<_Event> _buffer = [];
  static bool _enabled = true;

  /// 记录一个埋点事件。
  ///
  /// 当 [enabled] 为 `false` 时静默忽略。事件会先写入内存缓冲 [_buffer]，
  /// 随后在开发环境打印到控制台，生产环境可替换为 Firebase / Amplitude 上报。
  ///
  /// [name] 事件名称（如 `"answer"`, `"level_up"`, `"screen_view"`）。
  /// [params] 可选的事件参数 map。
  static void log(String name, [Map<String, dynamic>? params]) {
    if (!_enabled) return;
    _buffer.add(_Event(name, params));
    // In dev: print to console. In prod: send to Firebase/Amplitude.
    // ignore: avoid_print
    print('[Analytics] $name ${params ?? {}}');
  }

  /// 记录屏幕浏览事件（`screen_view`）。
  ///
  /// [screenName] 屏幕名称，如 `"HomePage"`, `"QuizPage"`。
  static void screen(String screenName) => log('screen_view', {'screen': screenName});

  /// 记录答题事件（`answer`）。
  ///
  /// [module] 模块标识，如 `"sima_yi"`。
  /// [correct] 是否正确作答。
  static void answered(String module, bool correct) => log('answer', {'module': module, 'correct': correct});

  /// 记录升级事件（`level_up`）。
  ///
  /// [newLevel] 达到的新等级。
  static void levelUp(int newLevel) => log('level_up', {'level': newLevel});

  /// 禁用埋点 — 后续 [log] 调用将被静默忽略。
  static void disable() => _enabled = false;

  /// 启用埋点 — 恢复 [log] 事件记录。
  static void enable() => _enabled = true;

  /// 取出当前缓冲中的所有事件并清空缓冲。
  ///
  /// 返回事件的快照列表，可用于批量上报到远程服务。
  static List<_Event> flush() { final b = List<_Event>.from(_buffer); _buffer.clear(); return b; }

  /// 重置到默认状态 — 清空缓冲并启用埋点。仅用于测试。
  static void reset() { _buffer.clear(); _enabled = true; }
}

/// 埋点事件数据模型（内部使用）。
///
/// 包含事件名称、可选参数及自动捕获的时间戳。
class _Event {
  final String name;
  final Map<String, dynamic>? params;
  final DateTime timestamp = DateTime.now();
  _Event(this.name, this.params);
}
