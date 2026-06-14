import 'package:hive_flutter/hive_flutter.dart';

/// Tracks daily hearts and session stats for the battle report.
class HeartService {
  static const _boxName = 'hearts';
  static const _keyHearts = 'hearts_remaining';
  static const _keyLastReset = 'last_reset_date';
  static const int maxHearts = 10;

  late Box _box;
  int _correct = 0;
  int _wrong = 0;
  int _combo = 0;
  int _maxCombo = 0;

  int get hearts => _box.get(_keyHearts, defaultValue: maxHearts);
  int get correct => _correct;
  int get wrong => _wrong;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get total => _correct + _wrong;
  double get accuracy => total == 0 ? 0 : _correct / total;

  bool get hasHearts => hearts > 0;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _checkDailyReset();
  }

  void _checkDailyReset() {
    final lastReset = _box.get(_keyLastReset, defaultValue: '');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastReset != today) {
      _box.put(_keyHearts, maxHearts);
      _box.put(_keyLastReset, today);
      _resetSessionStats();
    }
  }

  /// Consume one heart. Returns true if hearts hit 0 after this.
  bool consume() {
    final current = hearts;
    if (current <= 0) return false;
    _box.put(_keyHearts, current - 1);
    return hearts <= 0;
  }

  /// Record a correct answer. Updates session combo.
  void recordCorrect() {
    _correct++;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
  }

  /// Record a wrong answer. Breaks combo.
  void recordWrong() {
    _wrong++;
    _combo = 0;
  }

  /// Reset session stats (called at daily reset).
  void _resetSessionStats() {
    _correct = 0;
    _wrong = 0;
    _combo = 0;
    _maxCombo = 0;
  }

  Future<void> dispose() => _box.close();
}
