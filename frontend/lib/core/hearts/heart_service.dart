/// Heart/stamina system — 10 hearts/day, daily challenge, combo streaks.
///
/// Uses an in-memory counter backed by Hive for persistence.
/// The in-memory value avoids Hive read race conditions during
/// Provider lifecycle; Hive writes ensure survival across restarts.
import 'package:hive_flutter/hive_flutter.dart';

class HeartService {
  static const _boxName = 'hearts';
  static const _keyHearts = 'hearts_remaining';
  static const _keyLastReset = 'last_reset_date';
  static const _keyDailyUsed = 'daily_challenge_used';
  static const _keyAllTimeCombo = 'all_time_combo';
  static const int maxHearts = 10;
  static const int dailyChallengeMax = 3;

  late Box _box;

  // In-memory counters (Hive-backed)
  int _hearts = maxHearts;
  int _dailyUsed = 0;
  int _allTimeCombo = 0;

  // Session stats (memory only, reset daily)
  int _correct = 0;
  int _wrong = 0;
  int _combo = 0;
  int _maxCombo = 0;

  // ---- public getters ----

  int get hearts => _hearts;
  bool get hasHearts => _hearts > 0;
  int get correct => _correct;
  int get wrong => _wrong;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get total => _correct + _wrong;
  double get accuracy => total == 0 ? 0 : _correct / total;
  int get dailyChallengeRemaining =>
      (dailyChallengeMax - _dailyUsed).clamp(0, dailyChallengeMax);
  bool get canUseDailyChallenge => _dailyUsed < dailyChallengeMax;
  int get allTimeCombo => _allTimeCombo;

  // ---- lifecycle ----

  Future<void> init() async {
    _box = Hive.box(_boxName);
    _loadFromBox();
    _checkDailyReset();
  }

  void _loadFromBox() {
    _hearts = _box.get(_keyHearts, defaultValue: maxHearts);
    _dailyUsed = _box.get(_keyDailyUsed, defaultValue: 0);
    _allTimeCombo = _box.get(_keyAllTimeCombo, defaultValue: 0);
  }

  void _checkDailyReset() {
    final lastReset = _box.get(_keyLastReset, defaultValue: '');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastReset != today) {
      _hearts = maxHearts;
      _dailyUsed = 0;
      _box.put(_keyHearts, maxHearts);
      _box.put(_keyDailyUsed, 0);
      _box.put(_keyLastReset, today);
      _resetSessionStats();
    }
  }

  // ---- operations ----

  bool useDailyChallenge() {
    if (_dailyUsed >= dailyChallengeMax) return false;
    _dailyUsed++;
    _box.put(_keyDailyUsed, _dailyUsed);
    return true;
  }

  bool consume() {
    if (_hearts <= 0) return false;
    _hearts--;
    _box.put(_keyHearts, _hearts);
    return _hearts <= 0;
  }

  void recordCorrect() {
    _correct++;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _allTimeCombo++;
    _box.put(_keyAllTimeCombo, _allTimeCombo);
  }

  void recordWrong() {
    _wrong++;
    _combo = 0;
    _allTimeCombo = 0;
    _box.put(_keyAllTimeCombo, 0);
  }

  void _resetSessionStats() {
    _correct = 0;
    _wrong = 0;
    _combo = 0;
    _maxCombo = 0;
  }

  // ---- promo ----

  int get firstAppOpenMs {
    final v = _box.get('first_app_open_ms', defaultValue: -1);
    if (v == -1) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _box.put('first_app_open_ms', now);
      return now;
    }
    return v;
  }

  bool isLifetimePromoActive(bool isPremium) {
    if (isPremium) return false;
    final first = firstAppOpenMs;
    if (first == -1) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - first;
    return elapsed < 48 * 3600 * 1000;
  }

  Future<void> dispose() => _box.close();
}
