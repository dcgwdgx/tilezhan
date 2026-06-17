/// Heart/stamina system — 10/day, daily challenge, combo streaks.
///
/// Uses simple `int` fields for immediate reads/writes,
/// backed by Hive for persistence across app restarts.
/// Box lifecycle: opened once in main(), never closed during app lifetime.
import 'package:hive_flutter/hive_flutter.dart';

class HeartService {
  static const _boxName = 'hearts';
  static const _kH = 'hearts_remaining';
  static const _kDate = 'last_reset_date';
  static const _kDC = 'daily_challenge_used';
  static const _kCombo = 'all_time_combo';
  static const int maxHearts = 10;
  static const int dailyChallengeMax = 3;

  // Simple fields — always correct, no Hive dependency for reads
  int _hearts = maxHearts;
  int _dailyUsed = 0;
  int _allTimeCombo = 0;
  bool _initialized = false;

  // Session stats
  int _correct = 0, _wrong = 0, _combo = 0, _maxCombo = 0;

  int get hearts { _ensureInit(); return _hearts; }
  bool get hasHearts { _ensureInit(); return _hearts > 0; }
  int get dailyChallengeRemaining { _ensureInit(); return (dailyChallengeMax - _dailyUsed).clamp(0, dailyChallengeMax); }
  bool get canUseDailyChallenge { _ensureInit(); return _dailyUsed < dailyChallengeMax; }
  int get allTimeCombo { _ensureInit(); return _allTimeCombo; }
  int get correct => _correct;
  int get wrong => _wrong;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get total => _correct + _wrong;
  double get accuracy => total == 0 ? 0 : _correct / total;

  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    final box = Hive.box(_boxName);
    _hearts = box.get(_kH, defaultValue: maxHearts);
    _dailyUsed = box.get(_kDC, defaultValue: 0);
    _allTimeCombo = box.get(_kCombo, defaultValue: 0);
    // Check daily reset
    final last = box.get(_kDate, defaultValue: '');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (last != today) {
      _hearts = maxHearts;
      _dailyUsed = 0;
      box.put(_kH, maxHearts);
      box.put(_kDC, 0);
      box.put(_kDate, today);
      _correct = _wrong = _combo = _maxCombo = 0;
    }
  }

  Future<void> init() async {}
  void dispose() {}

  bool useDailyChallenge() {
    _ensureInit();
    if (_dailyUsed >= dailyChallengeMax) return false;
    _dailyUsed++;
    _ensurePersist();
    return true;
  }

  bool consume() {
    _ensureInit();
    if (_hearts <= 0) return false;
    _hearts--;
    _ensurePersist();
    return _hearts <= 0;
  }

  void recordCorrect() {
    _ensureInit();
    _correct++; _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _allTimeCombo++;
    _ensurePersist();
  }

  void recordWrong() {
    _ensureInit();
    _wrong++;
    _combo = 0; _allTimeCombo = 0;
    _ensurePersist();
  }

  void _ensurePersist() {
    final box = Hive.box(_boxName);
    box.put(_kH, _hearts);
    box.put(_kDC, _dailyUsed);
    box.put(_kCombo, _allTimeCombo);
  }

  int get firstAppOpenMs {
    final box = Hive.box(_boxName);
    final v = box.get('first_app_open_ms', defaultValue: -1);
    if (v == -1) {
      final now = DateTime.now().millisecondsSinceEpoch;
      box.put('first_app_open_ms', now);
      return now;
    }
    return v;
  }

  bool isLifetimePromoActive(bool isPremium) {
    if (isPremium) return false;
    final f = firstAppOpenMs;
    if (f == -1) return false;
    return DateTime.now().millisecondsSinceEpoch - f < 48 * 3600 * 1000;
  }
}
