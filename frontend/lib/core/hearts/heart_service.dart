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

  /// Hearts remaining for the current day (0–10).
  /// Triggers lazy initialisation from Hive on first access.
  int get hearts { _ensureInit(); return _hearts; }
  /// Whether the player can afford at least one more game round.
  /// Convenience getter; equivalent to `hearts > 0`.
  bool get hasHearts { _ensureInit(); return _hearts > 0; }
  /// Number of daily-challenge uses still available today (0–3).
  /// The daily challenge is a separate allowance from regular hearts.
  int get dailyChallengeRemaining { _ensureInit(); return (dailyChallengeMax - _dailyUsed).clamp(0, dailyChallengeMax); }
  /// Whether at least one daily-challenge use remains.
  /// Does NOT mutate state — call [useDailyChallenge] to consume one.
  bool get canUseDailyChallenge { _ensureInit(); return _dailyUsed < dailyChallengeMax; }
  /// Lifetime cumulative correct-answer count used for combo tracking.
  /// Resets to 0 on a wrong answer; persists across app restarts in Hive.
  int get allTimeCombo { _ensureInit(); return _allTimeCombo; }
  // ── Session stats (in-memory only, reset on daily reset) ──

  /// Correct answers in the current session.
  int get correct => _correct;
  /// Wrong answers in the current session.
  int get wrong => _wrong;
  /// Current consecutive correct streak in this session.
  int get combo => _combo;
  /// Highest [combo] reached in this session.
  int get maxCombo => _maxCombo;
  /// Total answers given in this session (correct + wrong).
  int get total => _correct + _wrong;
  /// Session accuracy as a fraction 0–1. Returns 0 when no answers have been given.
  double get accuracy => total == 0 ? 0 : _correct / total;

  /// Lazy-first-access initialiser: loads persisted state from Hive on the
  /// first public getter/method call, then is a no-op for the rest of the
  /// session.  Also performs the daily-reset check: if the stored date
  /// differs from today, hearts and daily-challenge uses are replenished
  /// and all session stats are zeroed.
  ///
  /// Pattern rationale: Hive boxes are opened once in `main()`, but
  /// concrete values are only pulled into memory fields on first touch.
  /// This avoids dependency on Hive for every read while keeping the
  /// public API synchronous (no `Future` needed).
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

  /// Placeholder initialiser kept for API compatibility.
  /// Actual initialisation happens lazily via [_ensureInit] on first access.
  Future<void> init() async {}
  /// Placeholder disposal kept for API compatibility.
  /// The Hive box is never closed during the app lifetime.
  void dispose() {}

  /// Consumes one daily-challenge use and persists the new count to Hive.
  /// Returns `true` when the use was granted, `false` when none remain.
  /// Does NOT affect the regular heart balance.
  bool useDailyChallenge() {
    _ensureInit();
    if (_dailyUsed >= dailyChallengeMax) return false;
    _dailyUsed++;
    _ensurePersist();
    return true;
  }

  /// Deducts one heart and persists the new balance to Hive.
  /// Returns `true` when the balance has reached zero (game-over signal),
  /// `false` when hearts still remain.
  /// Does nothing and returns `false` when hearts are already at 0.
  bool consume() {
    _ensureInit();
    if (_hearts <= 0) return false;
    _hearts--;
    _ensurePersist();
    return _hearts <= 0;
  }

  /// Records a correct answer: increments session [correct], session [combo],
  /// updates [maxCombo] when the current streak exceeds the previous peak,
  /// and advances the lifetime [allTimeCombo].
  /// Persists all durable fields to Hive.
  void recordCorrect() {
    _ensureInit();
    _correct++; _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _allTimeCombo++;
    _ensurePersist();
  }

  /// Records a wrong answer: increments session [wrong], resets both the
  /// current session combo and the lifetime [allTimeCombo] to 0.
  /// Persists all durable fields to Hive.
  void recordWrong() {
    _ensureInit();
    _wrong++;
    _combo = 0; _allTimeCombo = 0;
    _ensurePersist();
  }

  /// Writes the current in-memory values of the three durable fields
  /// (hearts remaining, daily-challenge usage, all-time combo) into Hive.
  /// Called after every mutation to keep the persistent store in sync.
  void _ensurePersist() {
    final box = Hive.box(_boxName);
    box.put(_kH, _hearts);
    box.put(_kDC, _dailyUsed);
    box.put(_kCombo, _allTimeCombo);
  }

  /// Timestamp (ms since epoch) of the very first app launch.
  /// Returns the stored value on subsequent calls; writes it once on the
  /// first call when no stored value exists.
  /// Used by [isLifetimePromoActive] to gate a 48 h promotional window.
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

  /// Whether the lifetime promotional offer is still active for a non-premium
  /// user.  The window is 48 hours from [firstAppOpenMs].
  /// Returns `false` immediately for premium users — the promo is irrelevant.
  bool isLifetimePromoActive(bool isPremium) {
    if (isPremium) return false;
    final f = firstAppOpenMs;
    if (f == -1) return false;
    return DateTime.now().millisecondsSinceEpoch - f < 48 * 3600 * 1000;
  }
}
