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
  // 内存事件缓冲 — 暂存尚未批量上报的 [_Event]，由 [flush] 清空取走。
  static final List<_Event> _buffer = [];
  // 埋点开关 — 为 false 时 [log] 静默丢弃所有事件，由 [disable]/[enable] 控制。
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
  static List<_Event> flush() {
    // 先复制再清空 — 避免调用方在遍历缓冲时因清空而产生并发修改异常。
    final b = List<_Event>.from(_buffer);
    _buffer.clear();
    return b;
  }

  /// 重置到默认状态 — 清空缓冲并启用埋点。仅用于测试。
  static void reset() { _buffer.clear(); _enabled = true; }

  /// 向后端分析系统发送事件（异步，不阻塞 UI）。
  ///
  /// [event] 事件名：app_open / hearts_depleted / promo_shown / daily_challenge_used。
  /// 后端已部署，HTTP 客户端接入后替换为实际 API 调用。
  static void trackBackend(String event, {String userId = ''}) {
    if (!_enabled) return;
    // TODO: DioClient.instance.post(ApiEndpoints.trackAnalytics,
    //     data: {'event': event, 'user_id': userId});
  }
}

/// 埋点事件数据模型（内部使用）。
///
/// 包含事件名称、可选参数及自动捕获的时间戳。
class _Event {
  // 事件名称，如 "answer", "level_up", "screen_view"。
  final String name;
  // 事件携带的可选键值对参数，如 {'module': 'sima_yi', 'correct': true}。
  final Map<String, dynamic>? params;
  // 事件创建时刻的时间戳，构造时自动捕获当前时间。
  final DateTime timestamp = DateTime.now();
  // 构造一个埋点事件，[name] 必填，[params] 可选。
  _Event(this.name, this.params);
}
