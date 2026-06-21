/// 爱心/体力系统 — 每日 10 颗爱心、每日挑战次数、连续答对连击。
///
/// 作为 TileZhan 核心经济系统之一，控制玩家每天可进行的游戏局数。
/// 使用纯 `int` 内存字段实现零延迟读写，底层由 Hive 提供跨应用重启的持久化。
///
/// **架构角色**: 领域服务层（Core Service），无 UI 依赖，可被任何页面直接调用。
///
/// **持久化策略**:
/// - Hive Box 在 `main()` 中打开一次，应用生命周期内永不关闭。
/// - 内存字段在首次公开访问时从 Hive 懒加载（见 [_ensureInit]）。
/// - 每次变更后立即写回 Hive（见 [_ensurePersist]），保证崩溃安全。
///
/// **每日重置规则**:
/// - 爱心数恢复为 [maxHearts]（10 颗）。
/// - 每日挑战次数恢复为 [dailyChallengeMax]（3 次）。
/// - 会话统计（正确/错误/连击）清零。
/// - 终身连击 [allTimeCombo] 不受每日重置影响。
///
/// **使用示例**:
/// ```dart
/// final hs = HeartService();
/// if (!hs.hasHearts) { showNoHeartsDialog(); return; }
/// bool isGameOver = hs.consume();  // 扣除一颗爱心
/// hs.recordCorrect();              // 记录答对
/// ```
import 'package:hive_flutter/hive_flutter.dart';

class HeartService {
  // ────────────────────────────────────────────
  //  Hive 存储键名常量（私有，外部不可见）
  // ────────────────────────────────────────────

  // Hive Box 名称，所有爱心相关数据存储在此 Box 中
  static const _boxName = 'hearts';
  // 键: 当前剩余爱心数
  static const _kH = 'hearts_remaining';
  // 键: 上次每日重置的日期（ISO 8601 日期部分，如 "2026-06-17"）
  static const _kDate = 'last_reset_date';
  // 键: 今日已使用的每日挑战次数
  static const _kDC = 'daily_challenge_used';
  // 键: 终身累计连击数（跨会话持久化）
  static const _kCombo = 'all_time_combo';

  /// 每日最大爱心数量。
  ///
  /// 每天初始为 10 颗，每次游戏消耗 1 颗。归零后当日无法再游戏
  /// （除非使用每日挑战次数或观看广告等外部补充途径）。
  static const int maxHearts = 10;

  /// 每日挑战每天最多可用次数。
  ///
  /// 每日挑战是一种独立于普通爱心的游戏入场券，消耗时不扣爱心。
  /// 每日重置恢复为 3 次。
  static const int dailyChallengeMax = 3;

  // ────────────────────────────────────────────
  //  内存字段（简单 int，读取零开销，不依赖 Hive）
  // ────────────────────────────────────────────

  // 当前剩余爱心数，初始值 [maxHearts]，首次访问时从 Hive 加载真实值
  int _hearts = maxHearts;
  // 今日已使用的每日挑战次数，首次访问时从 Hive 加载
  int _dailyUsed = 0;
  // 终身累计连击数（答对次数，答错归零），跨会话持久化在 Hive 中
  int _allTimeCombo = 0;
  // 标记是否已完成首次懒加载初始化，防止重复从 Hive 读取
  bool _initialized = false;

  // ────────────────────────────────────────────
  //  会话统计字段（仅内存，每日重置时清零，不持久化）
  // ────────────────────────────────────────────

  // 当前会话中答对次数
  int _correct = 0;
  // 当前会话中答错次数
  int _wrong = 0;
  // 当前会话中连续答对次数（答错即归零）
  int _combo = 0;
  // 当前会话中达到的最高连击数
  int _maxCombo = 0;

  // ════════════════════════════════════════════
  //  公开属性（Getters）— 游戏逻辑的主要查询入口
  // ════════════════════════════════════════════

  /// 今日剩余爱心数（范围 0 ~ [maxHearts]）。
  ///
  /// 每天初始为 10，每局游戏消耗 1 颗。归零后无法再开始新游戏。
  /// 首次访问时触发从 Hive 的懒加载初始化（见 [_ensureInit]）。
  int get hearts { _ensureInit(); return _hearts; }

  /// 玩家是否还有足够的爱心开始至少一局游戏。
  ///
  /// 等价于 `hearts > 0`，提供更具语义化的命名。
  /// UI 层通常用此 getter 决定"开始游戏"按钮是否可用。
  bool get hasHearts { _ensureInit(); return _hearts > 0; }

  /// 今日剩余的每日挑战次数（范围 0 ~ [dailyChallengeMax]）。
  ///
  /// 每日挑战是与普通爱心独立的游戏入场券：消耗时不扣爱心，
  /// 每日重置恢复为 3 次。当爱心耗尽时可作为补充游戏次数使用。
  int get dailyChallengeRemaining { _ensureInit(); return (dailyChallengeMax - _dailyUsed).clamp(0, dailyChallengeMax); }

  /// 是否还有至少一次每日挑战可用。
  ///
  /// 此 getter 只读不写——如需消耗一次，请调用 [useDailyChallenge]。
  bool get canUseDailyChallenge { _ensureInit(); return _dailyUsed < dailyChallengeMax; }

  /// 终身累计连击数，用于连击追踪与成就系统。
  ///
  /// 答对时 +1，答错时立即归零。跨应用重启持久化在 Hive 中。
  /// 每日重置不会清零此值——它是跨天的终身统计。
  int get allTimeCombo { _ensureInit(); return _allTimeCombo; }

  // ── 会话统计（仅内存，每日重置时清零，不持久化到 Hive）──

  /// 当前会话中答对的总次数。
  ///
  /// 每日重置时归零。仅存在于内存中，不持久化。
  int get correct => _correct;

  /// 当前会话中答错的总次数。
  ///
  /// 每日重置时归零。仅存在于内存中，不持久化。
  int get wrong => _wrong;

  /// 当前会话中连续答对的次数（当前连击）。
  ///
  /// 答对 +1，答错立即归零。用于 UI 展示连击动画/特效。
  int get combo => _combo;

  /// 当前会话中达到的最高连击数。
  ///
  /// 每次 [combo] 超过历史峰值时自动更新。
  /// 可用于展示"今日最佳连击"。
  int get maxCombo => _maxCombo;

  /// 当前会话中答题总数（正确 + 错误）。
  ///
  /// 算式：`_correct + _wrong`。每日重置时归零。
  int get total => _correct + _wrong;

  /// 当前会话的正确率，范围 0.0 ~ 1.0。
  ///
  /// 当 [total] 为 0（尚未答任何题）时返回 0.0，避免除零错误。
  /// 可用于展示"今日正确率"进度条或百分比。
  double get accuracy => total == 0 ? 0 : _correct / total;

  // ════════════════════════════════════════════
  //  私有方法 — 初始化、持久化
  // ════════════════════════════════════════════

  /// 懒加载初始化：在首次公开 getter 或方法调用时执行，后续调用为无操作。
  ///
  /// **执行步骤**:
  /// 1. 若已初始化（[_initialized] == true），直接返回。
  /// 2. 标记已初始化，防止重复加载。
  /// 3. 从 Hive Box 读取上次持久化的值：剩余爱心、每日挑战已用次数、终身连击。
  /// 4. 检查日期：若 Hive 中存储的日期与今天不一致，
  ///    执行每日重置——恢复满爱心、清零每日挑战、更新日期戳，
  ///    同时清零所有会话统计字段。
  ///
  /// **设计意图**:
  /// Hive Box 在 `main()` 中打开一次，但具体值只在首次触摸时才拉入内存字段。
  /// 这样既避免了每次读取都依赖 Hive（同步、零开销），
  /// 又保持了公开 API 的同步性（无需 `Future`）。
  ///
  /// **日期比较算法**:
  /// 使用 `DateTime.now().toIso8601String().substring(0, 10)` 提取当天日期部分
  /// （如 "2026-06-17"），与 Hive 中存储的上次重置日期字符串直接比较。
  /// 这种方法简单可靠，不涉及时区转换。
  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    try {
      final box = Hive.box(_boxName);
      _hearts = box.get(_kH, defaultValue: maxHearts);
      _dailyUsed = box.get(_kDC, defaultValue: 0);
      _allTimeCombo = box.get(_kCombo, defaultValue: 0);
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
    } catch (e) {
      // Hive corrupt — fall back to defaults so the app doesn't crash
      print('HeartService init failed: $e');
      _hearts = maxHearts;
      _dailyUsed = 0;
      _allTimeCombo = 0;
      _correct = _wrong = _combo = _maxCombo = 0;
    }
  }

  /// 占位初始化方法，保持 API 兼容性。
  ///
  /// 实际初始化已改为懒加载模式：首次访问任何公开 getter 或方法时，
  /// 由 [_ensureInit] 自动完成。此方法为空操作，仅用于满足调用方
  /// 可能存在的 `await heartService.init()` 调用约定。
  ///
  /// 如需显式触发初始化（例如在加载界面提前准备数据），
  /// 可直接访问 [hearts] 等 getter，无需调用此方法。
  Future<void> init() async {}

  /// 占位清理方法，保持 API 兼容性。
  ///
  /// Hive Box 在应用生命周期内永不关闭（由 `main()` 中的 `Hive.openBox` 管理），
  /// 因此此方法为空操作。如需手动释放资源，应由应用顶层统一管理 Hive 生命周期。
  void dispose() {}

  /// 消耗一次每日挑战次数并将新计数持久化到 Hive。
  ///
  /// **参数**: 无。
  ///
  /// **返回值**:
  /// - `true` — 消耗成功，每日挑战次数已扣减。
  /// - `false` — 今日每日挑战次数已用完（已达 [dailyChallengeMax]），无法再消耗。
  ///
  /// **副作用**: 不影响普通爱心余额（[hearts]）。仅在 [_ensurePersist] 中将
  /// 新的 `_dailyUsed` 写回 Hive。
  ///
  /// **典型调用场景**: 玩家点击"每日挑战"按钮开始一局特殊游戏时。
  bool useDailyChallenge() {
    _ensureInit();
    if (_dailyUsed >= dailyChallengeMax) return false;
    _dailyUsed++;
    _ensurePersist();
    return true;
  }

  /// 扣除一颗爱心并将新余额持久化到 Hive。
  ///
  /// **参数**: 无。
  ///
  /// **返回值**: 一个布尔值，**注意语义**：
  /// - `true` — 爱心已耗尽（`_hearts <= 0`），**游戏结束信号**，UI 应展示"爱心不足"提示。
  /// - `false` — 爱心仍有剩余，玩家可以继续游戏。
  ///
  /// **边界情况**:
  /// - 若爱心已为 0（`_hearts <= 0`），不执行任何操作并返回 `false`。
  ///
  /// **副作用**: 将新的 `_hearts` 值通过 [_ensurePersist] 写回 Hive。
  ///
  /// **典型调用场景**: 玩家点击"开始游戏"按钮后，在进入游戏前扣减爱心。
  /// 调用方应检查返回值 —— `true` 表示爱心耗尽，应引导玩家等待或使用每日挑战。
  bool consume() {
    _ensureInit();
    if (_hearts <= 0) return false;
    _hearts--;
    _ensurePersist();
    return _hearts <= 0;
  }

  /// 记录一次正确回答。
  ///
  /// **执行的更新**（按顺序）:
  /// 1. 会话答对数 [correct] +1。
  /// 2. 当前连击 [combo] +1。
  /// 3. 若当前连击超过历史最高 [maxCombo]，更新最高连击记录。
  /// 4. 终身连击 [allTimeCombo] +1（跨会话持久化）。
  /// 5. 将所有持久化字段写入 Hive。
  ///
  /// **典型调用场景**: 玩家在游戏中答对一道题后立即调用。
  /// 调用方通常紧接着检查 [combo] 来判断是否触发连击特效。
  void recordCorrect() {
    _ensureInit();
    // 会话统计：答对数 +1，连击 +1
    _correct++; _combo++;
    // 若当前连击突破历史最高，更新峰值记录
    if (_combo > _maxCombo) _maxCombo = _combo;
    // 终身连击（跨天持久化）累加
    _allTimeCombo++;
    _ensurePersist();
  }

  /// 记录一次错误回答。
  ///
  /// **执行的更新**（按顺序）:
  /// 1. 会话答错数 [wrong] +1。
  /// 2. 当前连击 [combo] 归零（连续答对中断）。
  /// 3. 终身连击 [allTimeCombo] 归零（跨会话持久化的连击也重置）。
  /// 4. 将所有持久化字段写入 Hive。
  ///
  /// **注意**: [maxCombo] 保持不变——它记录的是"曾达到的最高值"，
  /// 即使当前连击中断也不应回退。
  ///
  /// **典型调用场景**: 玩家在游戏中答错一道题后立即调用。
  void recordWrong() {
    _ensureInit();
    _wrong++;
    // 答错即中断：当前连击和终身连击全部归零
    _combo = 0; _allTimeCombo = 0;
    _ensurePersist();
  }

  // 将三个持久化字段的当前内存值同步写入 Hive。
  //
  // 每次变更操作（consume、useDailyChallenge、recordCorrect、recordWrong）
  // 结束后立即调用，确保即使应用崩溃，Hive 中保存的也是最新状态。
  //
  // 写回字段：
  // - `_kH` ← `_hearts`（剩余爱心数）
  // - `_kDC` ← `_dailyUsed`（每日挑战已用次数）
  // - `_kCombo` ← `_allTimeCombo`（终身连击数）
  //
  // 会话统计字段（_correct、_wrong、_combo、_maxCombo）不在此持久化，
  // 因为它们是每日临时数据，不需要跨应用重启保存。
  void _ensurePersist() {
    final box = Hive.box(_boxName);
    box.put(_kH, _hearts);
    box.put(_kDC, _dailyUsed);
    box.put(_kCombo, _allTimeCombo);
  }

  /// 应用首次启动的时间戳（自 Unix 纪元以来的毫秒数）。
  ///
  /// **行为**:
  /// - 首次调用时：将当前时间戳写入 Hive，并返回该值。
  /// - 后续调用时：直接返回 Hive 中已存储的首次启动时间戳。
  ///
  /// **用途**: 供 [isLifetimePromoActive] 使用，判定用户是否处于
  /// 首次安装后的 48 小时促销窗口内。
  ///
  /// **存储键**: `'first_app_open_ms'`，写入同一个 `hearts` Hive Box。
  int get firstAppOpenMs {
    final box = Hive.box(_boxName);
    final v = box.get('first_app_open_ms', defaultValue: -1);
    if (v == -1) {
      // 首次调用：记录当前时间为应用首次启动时间
      final now = DateTime.now().millisecondsSinceEpoch;
      box.put('first_app_open_ms', now);
      return now;
    }
    return v;
  }

  /// 判断终身促销优惠是否对非 Premium 用户仍然有效。
  ///
  /// **参数**:
  /// - `isPremium`: 用户当前是否已是 Premium 会员。
  ///
  /// **返回值**:
  /// - `true` — 促销窗口仍然开启，可向用户展示终身购买优惠。
  /// - `false` — 不满足促销条件（已是 Premium 会员，或已超过 48 小时窗口，或尚未记录首次启动时间）。
  ///
  /// **促销规则**:
  /// 1. Premium 用户直接返回 `false`——已付费用户无需看到促销。
  /// 2. 非 Premium 用户：从 [firstAppOpenMs] 起 48 小时（即 172,800,000 毫秒）内返回 `true`。
  /// 3. 超过 48 小时后返回 `false`，促销窗口关闭。
  ///
  /// **注意**: 此方法每次调用都会访问 [firstAppOpenMs] getter，
  /// 首次调用时会触发写入 Hive 记录首次启动时间。
  bool isLifetimePromoActive(bool isPremium) {
    // Premium 用户不需要看促销
    if (isPremium) return false;
    final f = firstAppOpenMs;
    // 防御：若 firstAppOpenMs 返回 -1（理论上不会，但保守处理）
    if (f == -1) return false;
    // 48 小时窗口：当前时间 - 首次启动时间 < 48 小时（毫秒）
    return DateTime.now().millisecondsSinceEpoch - f < 48 * 3600 * 1000;
  }
}
