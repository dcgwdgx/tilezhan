/// SM-2 间隔重复系统的数据模型。
///
/// 包含不可变的 [SrsItem] 值对象及其 JSON 序列化/反序列化辅助方法。
/// 核心职责：记录单个学习条目的复习历史（重复次数、间隔天数、难度因子），
/// 并为复习调度器提供 [errorWeight] 优先级排序依据。
///
/// 典型使用场景：
/// - 复习调度器读取所有 SrsItem，按 errorWeight 降序排列，优先展示最需复习的内容
/// - 用户评分后，调度器调用 copyWith 生成更新后的条目，再持久化到本地存储
/// - 通过 toJson / fromJson 与 SharedPreferences 或 SQLite 进行序列化交互
///
/// 算法参考：SM-2 (SuperMemo 2) 间隔重复算法。
/// 优先级启发式详见 [SrsItem.errorWeight]。

/// SM-2 间隔重复系统中单个学习条目的不可变数据模型。
///
/// 记录该条目的完整复习历史，包括：
/// - 重复次数 ([reps])：连续正确回答的次数
/// - 间隔天数 ([interval])：距离下次复习的天数
/// - 难度因子 ([ef])：SM-2 算法中的 Easiness Factor，影响间隔增长速度
///
/// 核心计算属性 [errorWeight] 用于跨条目优先级排序——错误率越高的条目越优先出现。
/// 所有字段均为不可变（immutable），修改需通过 [copyWith] 创建新实例。
class SrsItem {
  /// 学习条目的唯一标识符，对应闪卡 ID 或何切题目 ID。
  final String itemId;

  /// 条目类型，决定调度器使用何种评分逻辑。
  /// 可选值：`'flashcard'`（闪卡模式）或 `'nanikiru'`（何切模式）。
  final String type;

  /// SM-2 难度因子（Easiness Factor），初始值 2.5。
  /// 范围通常为 1.3~2.5：评分高则升高（间隔增长更快），评分低则降低（间隔增长更慢）。
  /// 最低不低于 1.3，防止间隔无限缩短。
  final double ef;

  /// 连续正确回答的次数计数器。
  /// 每次评分 ≥ 3（及格）时 +1；评分 < 3 时重置为 0。
  final int reps;

  /// 下次复习前的间隔天数。
  /// SM-2 算法根据 reps 和 ef 自动计算：reps=0→1天, reps=1→6天, reps≥2→interval×ef。
  final int interval;

  /// 下次复习的目标时间戳（epoch 毫秒）。
  /// 计算方式：当前时间 + interval × 86400000（一天毫秒数）。
  /// 为 0 表示尚未安排复习（新条目或刚创建）。
  final int nextReviewAt;

  /// 累计错误次数，用于计算 [errorWeight]。
  /// 每次评分 < 3（不及格）时 +1；不计入连续正确次数 [reps]。
  final int errors;

  /// 条目创建时间戳（epoch 毫秒）。
  /// 用于按时间筛选、统计以及生命周期管理。
  final int createdAt;

  /// 最近一次复习的时间戳（epoch 毫秒）。
  /// 用于判断条目是否"过期"（当前时间 > nextReviewAt）以及生成复习统计。
  final int lastReviewedAt;

  /// 创建一个新的 SM-2 间隔重复条目。
  ///
  /// [type] 必须为 `'flashcard'`（闪卡）或 `'nanikiru'`（何切题目）。
  /// [ef] 默认为 SM-2 算法规定的初始难度因子 2.5。
  /// [interval] 单位为天；[nextReviewAt]、[createdAt]、[lastReviewedAt] 均为 epoch 毫秒时间戳。
  ///
  /// 典型调用示例：
  /// ```dart
  /// SrsItem(itemId: 'card_001', type: 'flashcard');
  /// ```
  const SrsItem({
    required this.itemId,
    required this.type,
    this.ef = 2.5,
    this.reps = 0,
    this.interval = 1,
    this.nextReviewAt = 0,
    this.errors = 0,
    this.createdAt = 0,
    this.lastReviewedAt = 0,
  });

  /// 错误权重——用于跨条目优先级排序的核心计算属性。
  ///
  /// 返回值越高，表示该条目越"紧迫"，应优先展示给用户复习。
  ///
  /// 计算公式：
  /// - 若 [reps] 为 0（尚无连续正确记录）：直接返回 [errors]，即所有错误都算作紧迫度。
  /// - 若 [reps] > 0：返回 `errors / (reps + 1)`，即"错误率"。
  ///   分母 +1 可避免除零，同时让仅有 1 次正确的条目不至于权重骤降。
  ///
  /// 设计意图：频繁出错的条目比偶尔出错的条目更需复习；随着连续正确次数增加，
  /// 权重递减，条目自然后移——这正是 SM-2 优先级调度的核心启发式。
  ///
  /// 返回值为 [double]：0.0 表示无错误（最低优先级），无理论上限（但 errors 通常为小整数）。
  double get errorWeight =>
      reps == 0 ? errors.toDouble() : errors / (reps + 1);

  /// 创建当前条目的不可变副本，可选覆盖指定字段。
  ///
  /// 所有参数均为可选命名参数；未提供的字段将沿用当前实例的值。
  /// [itemId] 和 [type] 不可修改——因为它们是条目的身份标识。
  ///
  /// 典型用法（复习调度器评分后更新状态）：
  /// ```dart
  /// final updated = item.copyWith(
  ///   reps: newReps,
  ///   interval: newInterval,
  ///   nextReviewAt: scheduledTime,
  ///   errors: item.errors + 1,
  ///   lastReviewedAt: DateTime.now().millisecondsSinceEpoch,
  /// );
  /// ```
  SrsItem copyWith({
    double? ef, int? reps, int? interval, int? nextReviewAt,
    int? errors, int? createdAt, int? lastReviewedAt,
  }) => SrsItem(
    itemId: itemId, type: type,
    ef: ef ?? this.ef, reps: reps ?? this.reps,
    interval: interval ?? this.interval,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    errors: errors ?? this.errors,
    createdAt: createdAt ?? this.createdAt,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
  );

  /// 将当前条目序列化为 JSON 兼容的 [Map] 对象。
  ///
  /// 所有字段按原始类型写入：String 字段原样保留，int/double 字段直接映射。
  /// 用于持久化存储（SharedPreferences、SQLite、文件系统）或网络传输。
  ///
  /// 返回值包含所有 10 个字段的完整映射，不会省略默认值字段。
  Map<String, dynamic> toJson() => {
    'itemId':itemId,'type':type,'ef':ef,'reps':reps,'interval':interval,
    'nextReviewAt':nextReviewAt,'errors':errors,
    'createdAt':createdAt,'lastReviewedAt':lastReviewedAt,
  };
  /// 从 JSON 兼容的 [Map] 对象反序列化构造一个 [SrsItem] 实例。
  ///
  /// 工厂构造函数，返回新创建的 [SrsItem] 对象。
  /// 所有字段均有默认值兜底，可安全处理部分字段缺失的旧版数据：
  /// - [type] 缺失时默认 `'flashcard'`（向后兼容仅闪卡版本的存储数据）
  /// - [ef] 缺失时默认 2.5（SM-2 标准初始值）
  /// - 数值字段缺失时默认 0（[reps]、[errors]、[createdAt]、[lastReviewedAt]）
  /// - [interval] 缺失时默认 1（首次复习间隔 1 天）
  ///
  /// 参数 [j] 为 JSON 解码后的 Map，键名应与 [toJson] 输出一致（驼峰命名）。
  factory SrsItem.fromJson(Map<String, dynamic> j) => SrsItem(
    itemId: j['itemId'], type: j['type']??'flashcard',
    ef: (j['ef'] as num?)?.toDouble()??2.5, reps: j['reps']??0,
    interval: j['interval']??1, nextReviewAt: j['nextReviewAt']??0,
    errors: j['errors']??0, createdAt: j['createdAt']??0,
    lastReviewedAt: j['lastReviewedAt']??0,
  );
}
