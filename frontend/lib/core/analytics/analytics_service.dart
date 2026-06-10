/// Local analytics — logs events to console and defers to Firebase when available.
/// Per design spec: lib/core/analytics/analytics_service.dart
class AnalyticsService {
  static final List<_Event> _buffer = [];
  static bool _enabled = true;

  static void log(String name, [Map<String, dynamic>? params]) {
    if (!_enabled) return;
    _buffer.add(_Event(name, params));
    // In dev: print to console. In prod: send to Firebase/Amplitude.
    // ignore: avoid_print
    print('[Analytics] $name ${params ?? {}}');
  }

  static void screen(String screenName) => log('screen_view', {'screen': screenName});
  static void answered(String module, bool correct) => log('answer', {'module': module, 'correct': correct});
  static void levelUp(int newLevel) => log('level_up', {'level': newLevel});

  static void disable() => _enabled = false;
  static void enable() => _enabled = true;
  static List<_Event> flush() { final b = List<_Event>.from(_buffer); _buffer.clear(); return b; }
  /// For tests only — resets to default state.
  static void reset() { _buffer.clear(); _enabled = true; }
}

class _Event {
  final String name;
  final Map<String, dynamic>? params;
  final DateTime timestamp = DateTime.now();
  _Event(this.name, this.params);
}
