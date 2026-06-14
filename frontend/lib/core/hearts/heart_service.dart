import 'package:hive_flutter/hive_flutter.dart';

/// 体力 + 每日挑战 + 连斩追踪，Hive 持久化到本地。
///
/// 核心规则（对齐 tilezhan-pricing.md §四）：
/// - 每天 10 心，答对扣 1 心，答错不扣（进错题池免费练）
/// - 每日挑战前 3 题不耗体力，次日重置
/// - 连续答对 10 题触发组合促销（全时连斩跨会话不重置）
/// - 错题重练永远免费（调用方在消耗前自行判断）
class HeartService {
  // ---- Hive key 常量 ----
  static const _boxName = 'hearts';
  static const _keyHearts = 'hearts_remaining';
  static const _keyLastReset = 'last_reset_date';
  static const _keyDailyUsed = 'daily_challenge_used';
  static const _keyAllTimeCombo = 'all_time_combo';
  static const int maxHearts = 10;
  static const int dailyChallengeMax = 3;

  late Box _box;

  // ---- 会话战绩（仅内存，每日重置）----
  int _correct = 0;
  int _wrong = 0;
  int _combo = 0;
  int _maxCombo = 0;

  // ---- 体力的读写 ----

  /// 剩余心数。每日重置回 [maxHearts]。
  int get hearts => _box.get(_keyHearts, defaultValue: maxHearts);
  bool get hasHearts => hearts > 0;

  // ---- 会话战绩 ----

  int get correct => _correct;
  int get wrong => _wrong;
  /// 当前连斩（答错归零）。
  int get combo => _combo;
  /// 本次会话最高连斩数。
  int get maxCombo => _maxCombo;
  /// 总答题次数。
  int get total => _correct + _wrong;
  /// 正确率 [0–1]，无答题返回 0。
  double get accuracy => total == 0 ? 0 : _correct / total;

  // ---- 每日挑战（每日 3 题免体力）----

  /// 今日已使用的免费挑战次数（持久化，每日重置）。
  int get dailyChallengeUsed => _box.get(_keyDailyUsed, defaultValue: 0);
  /// 今日剩余免费挑战次数。
  int get dailyChallengeRemaining =>
      (dailyChallengeMax - dailyChallengeUsed).clamp(0, dailyChallengeMax);
  /// 是否还有免费挑战可用。
  bool get canUseDailyChallenge => dailyChallengeRemaining > 0;

  // ---- 全时连斩（触发组合促销）----

  /// 跨会话连续正确数（持久化，答错归零，每日不重置）。
  int get allTimeCombo => _box.get(_keyAllTimeCombo, defaultValue: 0);

  // ---- 生命周期 ----

  /// 打开 Hive Box 并检查是否需要每日重置。
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _checkDailyReset();
  }

  /// 日期变化 → 回满心数、清零每日挑战和会话战绩。
  void _checkDailyReset() {
    final lastReset = _box.get(_keyLastReset, defaultValue: '');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastReset != today) {
      _box.put(_keyHearts, maxHearts);
      _box.put(_keyDailyUsed, 0);
      _box.put(_keyLastReset, today);
      _resetSessionStats();
    }
  }

  // ---- 核心操作 ----

  /// 使用一次每日挑战免费机会。成功返回 true，已用完返回 false。
  bool useDailyChallenge() {
    if (!canUseDailyChallenge) return false;
    _box.put(_keyDailyUsed, dailyChallengeUsed + 1);
    return true;
  }

  /// 消耗 1 心。返回 true 表示心已耗尽 → 触发战绩弹窗。
  bool consume() {
    final current = hearts;
    if (current <= 0) return false;
    _box.put(_keyHearts, current - 1);
    return hearts <= 0;
  }

  /// 记录正确回答 → 更新会话战绩 + 全时连斩 +1。
  void recordCorrect() {
    _correct++;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _box.put(_keyAllTimeCombo, allTimeCombo + 1);
  }

  /// 记录错误回答 → 归零当前连斩和全时连斩。
  void recordWrong() {
    _wrong++;
    _combo = 0;
    _box.put(_keyAllTimeCombo, 0);
  }

  /// 每日重置时清零内存战绩。
  void _resetSessionStats() {
    _correct = 0;
    _wrong = 0;
    _combo = 0;
    _maxCombo = 0;
  }

  Future<void> dispose() => _box.close();
}
