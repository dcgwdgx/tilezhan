/// SM-2 间隔重复系统（Spaced Repetition System）的数据模型层。
///
/// 本文件提供 SM-2 算法中单个学习条目的不可变数据封装：
/// - [SrsItem]：记录学习条目的完整复习历史（重复次数、间隔天数、难度因子、错误计数等）。
/// - 提供 [toJson] / [fromJson] 实现 JSON 序列化与反序列化，用于 SharedPreferences、
///   SQLite 或文件系统持久化。
/// - 提供 [copyWith] 不可变更新模式，确保状态变更安全可追踪。
///
/// 核心设计：
/// - **不可变（immutable）**：所有字段为 `final`，修改只能通过 [copyWith] 创建新实例，
///   避免副作用导致的状态不一致。
/// - **优先级排序**：[errorWeight] 计算属性提供跨条目的复习优先级依据——错误率高的条目
///   自动获得更高权重，在复习队列中优先展示。
/// - **SM-2 兼容**：[ef]（Easiness Factor）、[reps]（连续正确次数）、[interval]（间隔天数）
///   三个核心字段严格按照 SuperMemo 2 算法规范定义。
///
/// 典型使用场景：
/// 1. 复习调度器读取所有 SrsItem，按 [errorWeight] 降序排列，优先展示最需复习的内容。
/// 2. 用户评分后，调度器根据 SM-2 规则计算新的 reps/interval/ef，调用 [copyWith] 生成
///    更新后的条目，再通过 [toJson] 持久化。
/// 3. 应用启动时，通过 [fromJson] 从本地存储恢复所有条目。
///
/// 算法参考：SuperMemo 2 (SM-2)，详见 https://www.supermemo.com/en/archives1990-2015/english/ol/sm2

/// SM-2 间隔重复系统中单个学习条目的不可变数据模型。
///
/// 每个 [SrsItem] 实例对应一个学习内容（闪卡或何切题目），记录其完整的复习历史。
/// 复习调度器根据这些历史数据决定每个条目的复习时机和优先级。
///
/// ## 状态字段（SM-2 核心三要素）
/// - [ef]：难度因子（Easiness Factor），取值范围 1.3~2.5，控制间隔增长速度。
///   初始值 2.5，每次评分后根据用户反馈动态调整。
/// - [reps]：连续正确次数，决定条目处于 SM-2 的哪个学习阶段（新学/复习/巩固）。
///   评分 ≥ 3（及格）时递增，评分 < 3 时归零。
/// - [interval]：当前间隔天数，由 SM-2 算法根据 [reps] 和 [ef] 自动计算。
///   reps=0 → 1天，reps=1 → 6天，reps≥2 → interval × ef。
///
/// ## 辅助字段
/// - [nextReviewAt]：下次复习的绝对时间戳（epoch 毫秒），用于判断条目是否"到期"。
/// - [errors]：累计错误次数，驱动 [errorWeight] 优先级排序。
/// - [createdAt] / [lastReviewedAt]：生命周期时间戳，用于统计和筛选。
///
/// ## 不可变设计
/// 所有字段均为 `final`。修改状态时调用 [copyWith] 创建新实例，原始实例不受影响。
/// 这确保了并发安全，也便于与状态管理框架（如 Riverpod、Bloc）配合使用。
///
/// ## 序列化
/// 支持与 JSON 双向转换（[toJson] / [fromJson]），可直接存入 SharedPreferences
/// 的字符串字段或 SQLite 的 TEXT 列。
class SrsItem {
  // =========================================================================
  // 字段
  // =========================================================================

  /// 学习条目的唯一标识符（业务主键）。
  ///
  /// 在闪卡模式下对应该闪卡的 ID，在何切模式下对应该何切题目的 ID。
  /// 此字段不可变——一旦创建便不可修改（[copyWith] 不允许覆写此字段）。
  /// 用于在复习队列中定位条目、去重，以及关联对应的学习内容。
  final String itemId;

  /// 条目类型，决定调度器采用何种评分逻辑和 UI 展示方式。
  ///
  /// 可选值：
  /// - `'flashcard'`：闪卡模式。用户看正面→回忆反面→自评 0~5 分。
  ///   评分标准：完全想不起=0，想起但困难=1~2，想起较慢=3，轻松想起=4，瞬间想起=5。
  /// - `'nanikiru'`：何切（麻将舍牌判断）模式。用户看到牌谱→选择舍牌→
  ///   系统对比正解后给出 0~5 分。评分标准基于选择的正确性和速度。
  ///
  /// 调度器根据此字段调用不同的 SM-2 评分计算函数。
  final String type;

  /// SM-2 难度因子（Easiness Factor），简写 EF。
  ///
  /// 控制间隔增长速率的核心参数：
  /// - 初始值：2.5（SM-2 算法规定的新条目默认值）。
  /// - 取值范围：最小 1.3（SM-2 算法的硬下限，防止间隔无限缩短）。
  ///   理论上可超过 2.5，但实践中很少超过 3.0。
  /// - 调整规则（SM-2 标准公式）：`EF' = EF + (0.1 - q*(5-q)*0.08)`
  ///   其中 q 为用户评分（0~5）。q 越高 EF 升得越多，间隔增长越快；
  ///   q 越低 EF 下降越多，间隔增长越慢。（具体计算在调度器而非本模型。）
  ///
  /// 注意：EF 变化直接影响 [interval] 的计算结果，因此即使 [reps] 相同，
  /// EF 不同的条目其下次复习时间也会不同。
  final double ef;

  /// 连续正确回答的次数计数器，SM-2 算法的核心状态机变量。
  ///
  /// 决定了条目当前所处的学习阶段：
  /// - **0**：新条目或刚经历过错误。下次间隔固定为 1 天（短期记忆巩固阶段）。
  /// - **1**：刚通过第一次复习。下次间隔固定为 6 天（过渡到长期记忆）。
  /// - **≥ 2**：进入长期记忆阶段。间隔 = [interval] × [ef]（指数增长）。
  ///
  /// 更新规则（在调度器中执行）：
  /// - 评分 ≥ 3（及格）：reps = reps + 1（连续正确计数递增）。
  /// - 评分 < 3（不及格）：reps = 0（归零，条目退回短期记忆阶段）。
  final int reps;

  /// 下次复习前的间隔天数（整数天）。
  ///
  /// 由 SM-2 算法自动计算，公式取决于 [reps]：
  /// - reps = 0 → interval = 1（新条目/重置后：1天后复习）
  /// - reps = 1 → interval = 6（首次通过：6天后复习）
  /// - reps ≥ 2 → interval = round(上一次interval × ef)（长期记忆：指数增长）
  ///
  /// 此值由调度器在评分后通过 [copyWith] 写入，本模型不自行计算。
  final int interval;

  /// 下次复习的目标时间戳，以 epoch 毫秒（UTC）表示。
  ///
  /// 计算方式：`nextReviewAt = lastReviewedAt + interval × 86400000`
  /// （86400000 = 一天的毫秒数 = 24 × 60 × 60 × 1000）。
  ///
  /// 特殊值：
  /// - **0**：表示尚未安排复习（新创建或刚从存储恢复但未初始化）。
  ///   调度器应将此类条目视为"立即可复习"。
  ///
  /// 调度器通过比较 `DateTime.now().millisecondsSinceEpoch > nextReviewAt`
  /// 来判断条目是否"到期"需要复习。
  final int nextReviewAt;

  /// 累计错误次数（评分 < 3 的次数总和），不依赖于连续正确计数。
  ///
  /// 每次评分 < 3（不及格）时 +1。与 [reps] 不同，[errors] 只增不减——
  /// 即使后续连续正确，之前的错误也不会被抹去。这确保 [errorWeight] 能
  /// 真实反映条目的历史困难程度。
  ///
  /// 用途：作为 [errorWeight] 的分子，驱动跨条目的复习优先级排序。
  /// 错误越多的条目越"棘手"，越需要频繁复习。
  final int errors;

  /// 条目创建时间戳，以 epoch 毫秒（UTC）表示。
  ///
  /// 在条目首次创建时由调度器设置（通常取 `DateTime.now().millisecondsSinceEpoch`）。
  /// 用途：
  /// - 按时间筛选（如"仅显示本周新增的条目"）。
  /// - 统计（如"平均多少天后条目进入长期记忆阶段"）。
  /// - 生命周期管理（如"删除超过 90 天未复习的条目"）。
  final int createdAt;

  /// 最近一次复习（用户评分）的时间戳，以 epoch 毫秒（UTC）表示。
  ///
  /// 每次用户完成评分后由调度器更新。用途：
  /// - 与 [nextReviewAt] 配合，判断条目是否"过期"（当前时间 > nextReviewAt）。
  /// - 生成复习统计（如"今天复习了多少条目"、"平均复习间隔"）。
  /// - 检测异常（如 lastReviewedAt 远早于 nextReviewAt，说明条目被长期忽略）。
  ///
  /// 默认值 0 表示从未被复习过（新创建）。
  final int lastReviewedAt;

  // =========================================================================
  // 构造函数
  // =========================================================================

  /// 创建一个新的 SM-2 间隔重复条目（const 构造函数，支持编译期常量）。
  ///
  /// 所有字段除 [itemId] 和 [type] 外均有默认值，符合 SM-2 算法的新条目初始状态：
  /// - [ef] 默认 2.5（SM-2 标准初始难度因子）。
  /// - [reps] 默认 0（尚未连续正确回答）。
  /// - [interval] 默认 1（首次复习间隔 1 天）。
  /// - [nextReviewAt] 默认 0（表示尚未安排复习时间）。
  /// - [errors] 默认 0（尚无错误记录）。
  /// - [createdAt] 默认 0（由调度器在持久化前设置实际时间戳）。
  /// - [lastReviewedAt] 默认 0（尚未被复习过）。
  ///
  /// [type] 参数必须是 `'flashcard'` 或 `'nanikiru'`，调度器依赖此值选择评分逻辑。
  ///
  /// 典型调用示例：
  /// ```dart
  /// // 最简创建（使用所有默认值）
  /// final item = SrsItem(itemId: 'card_001', type: 'flashcard');
  ///
  /// // 带创建时间的完整创建
  /// final item = SrsItem(
  ///   itemId: 'tile_042', type: 'nanikiru',
  ///   createdAt: DateTime.now().millisecondsSinceEpoch,
  /// );
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

  // =========================================================================
  // 计算属性
  // =========================================================================

  /// 错误权重——跨条目复习优先级排序的核心计算属性。
  ///
  /// 返回值越高，表示该条目历史错误比例越高，越"紧迫"，应优先展示给用户复习。
  /// 调度器读取所有条目后按此值降序排列，生成复习队列。
  ///
  /// ## 计算公式
  ///
  /// 采用两段式计算，兼顾新条目和已复习条目：
  ///
  /// ```
  /// 若 reps == 0（暂无连续正确记录）:
  ///   errorWeight = errors（纯错误数，每错一次紧迫度 +1）
  ///
  /// 若 reps > 0（已有连续正确记录）:
  ///   errorWeight = errors / (reps + 1)（错误率，分母 +1 防除零且平滑过渡）
  /// ```
  ///
  /// ## 设计意图
  ///
  /// - **新条目/经常出错的条目**（reps=0）：[errors] 直接映射为权重，每次错误
  ///   都增大紧迫度。这确保"反复记不住"的条目总是排在最前面。
  /// - **已进入稳定复习的条目**（reps>0）：权重 = 错误率。随着 [reps] 增长，
  ///   分母增大，权重自然递减，正确率高的条目自动后移——减少不必要的复习，
  ///   把时间留给真正困难的条目。
  /// - **分母 +1**：避免 reps=1 时 weight = errors（跳变过大），让从 reps=0
  ///   到 reps=1 的过渡更平滑。例如 errors=3, reps=0→weight=3.0；
  ///   reps=1→weight=3/(1+1)=1.5（而非 3/1=3.0）。
  ///
  /// ## 返回值
  ///
  /// [double] 类型：
  /// - 0.0：无错误记录（最低优先级，可安全延后复习）。
  /// - 正值：错误越多/正确越少 → 值越大 → 优先级越高。无理论上限。
  ///
  /// ## 局限性
  ///
  /// 此权重仅基于历史错误率，不直接考虑：
  /// - 距上次复习的时间（[nextReviewAt] 已过期程度）。调度器需另外结合
  ///   "是否到期"来判断最终复习顺序。
  /// - 条目的绝对创建时间（新条目可能需要更多关注）。
  /// - 用户主动标记的"重点关注"标志。
  ///
  /// 这些因素由调度器在 [errorWeight] 基础上叠加处理。
  double get errorWeight =>
      // reps==0：尚无连续正确记录，直接用错误数作为权重
      reps == 0 ? errors.toDouble() : errors / (reps + 1);

  // =========================================================================
  // 不可变更新
  // =========================================================================

  /// 创建当前条目的不可变副本，可选覆盖指定字段。
  ///
  /// 所有参数均为可选命名参数（nullable）；未提供的字段沿用当前实例的值，
  /// 提供的字段覆盖当前值。这是函数式不可变更新的标准模式。
  ///
  /// ## 不可修改的字段
  /// - [itemId] 和 [type] 不接受参数覆盖——它们是条目的身份标识，
  ///   一旦创建便不可变。这在方法签名中体现：这两个字段不出现在参数列表中。
  ///
  /// ## null 安全性
  /// 使用 `??` 运算符实现 null-coalescing 回退：
  /// ```dart
  /// ef: ef ?? this.ef  // 若传入 null（未提供），沿用当前值
  /// ```
  /// 这意味着无法通过 [copyWith] 将字段"重置为默认值"——需要全新的构造函数。
  /// 这在 SM-2 场景下是合理的设计：复习状态总是从历史状态演化而来。
  ///
  /// ## 典型用法
  ///
  /// 复习调度器评分后更新条目状态：
  /// ```dart
  /// final now = DateTime.now().millisecondsSinceEpoch;
  /// final updated = item.copyWith(
  ///   reps: newReps,            // SM-2 计算的新 reps
  ///   interval: newInterval,    // SM-2 计算的新 interval
  ///   ef: newEf,                // SM-2 计算的新 ef
  ///   nextReviewAt: now + newInterval * 86400000, // 下次复习时间
  ///   errors: item.errors + 1,  // 若本次评分 < 3，累加错误
  ///   lastReviewedAt: now,      // 记录本次复习时间
  /// );
  /// ```
  ///
  /// ## 性能
  ///
  /// 每次调用创建一个全新的 [SrsItem] 实例。对于典型的复习场景（每次评分调用一次），
  /// 此开销可忽略不计。若需批量更新数百个条目，考虑使用 `List.map` + `copyWith`
  /// 的组合而非手动循环。
  SrsItem copyWith({
    double? ef, int? reps, int? interval, int? nextReviewAt,
    int? errors, int? createdAt, int? lastReviewedAt,
  }) => SrsItem(
    // itemId 和 type 不可变，直接沿用
    itemId: itemId, type: type,
    // 各字段：传入值 ?? 当前值（null 表示不覆盖）
    ef: ef ?? this.ef,
    reps: reps ?? this.reps,
    interval: interval ?? this.interval,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    errors: errors ?? this.errors,
    createdAt: createdAt ?? this.createdAt,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
  );

  // =========================================================================
  // 序列化
  // =========================================================================

  /// 将当前条目序列化为 JSON 兼容的 [Map] 对象。
  ///
  /// 所有 10 个字段均写入 Map，键名使用驼峰命名（camelCase），与 [fromJson] 的
  /// 输入格式一致。即使字段值为默认值（如 ef=2.5、interval=1）也会完整写入——
  /// 这避免了反序列化时"缺失字段 = 默认值"的歧义。
  ///
  /// ## 返回结构
  /// ```json
  /// {
  ///   "itemId": "card_001", "type": "flashcard", "ef": 2.5,
  ///   "reps": 3, "interval": 15, "nextReviewAt": 1718000000000,
  ///   "errors": 1, "createdAt": 1717000000000,
  ///   "lastReviewedAt": 1717900000000
  /// }
  /// ```
  ///
  /// ## 使用场景
  /// - **SharedPreferences**：`prefs.setString('srs_$itemId', jsonEncode(item.toJson()))`
  /// - **SQLite**：将 Map 各字段映射到列，或整体 JSON 存入 TEXT 列。
  /// - **网络同步**：作为 API 请求/响应的 body 数据。
  Map<String, dynamic> toJson() => {
    // 字符串字段：原样序列化
    'itemId': itemId,
    'type': type,
    // 数值字段：int → JSON number, double → JSON number（自动兼容）
    'ef': ef,
    'reps': reps,
    'interval': interval,
    'nextReviewAt': nextReviewAt,
    'errors': errors,
    'createdAt': createdAt,
    'lastReviewedAt': lastReviewedAt,
  };

  /// 从 JSON 兼容的 [Map] 对象反序列化构造一个 [SrsItem] 实例。
  ///
  /// 工厂构造函数（factory），不要求已存在实例，直接从 Map 创建新对象。
  /// 所有字段均有兜底默认值，可安全处理以下场景：
  ///
  /// ## 向后兼容性
  ///
  /// | 场景 | 处理方式 |
  /// |------|----------|
  /// | 旧版数据无 [type] 字段 | 默认 `'flashcard'`（仅闪卡版本的遗留数据） |
  /// | [ef] 字段缺失或类型异常 | `(j['ef'] as num?)?.toDouble() ?? 2.5`<br>先安全转型为 num→double，失败则回退到 SM-2 初始值 2.5 |
  /// | [interval] 缺失 | 默认 1（首次复习间隔） |
  /// | 其他 int 字段缺失 | 默认 0（表示未初始化状态） |
  ///
  /// ## 类型安全
  ///
  /// [ef] 的反序列化使用了三层安全链：
  /// 1. `j['ef']` — 从 Map 取值（可能为 null、int、double、String）
  /// 2. `as num?` — 若值为 int 或 double，转型为 num；否则返回 null（不抛异常）
  /// 3. `?.toDouble() ?? 2.5` — 若转型成功，转为 double；若任何一步失败，回退到 2.5
  ///
  /// 这确保即使存储数据被意外篡改（如 ef 被存为字符串 "2.5"），也不会导致崩溃。
  ///
  /// ## 参数
  /// - [j]：JSON 解码后的 Map，键名需与 [toJson] 输出一致（驼峰命名）。可包含部分字段。
  ///
  /// ## 返回值
  /// 新创建的 [SrsItem] 实例，所有字段均被填充（来自 Map 或默认值）。
  factory SrsItem.fromJson(Map<String, dynamic> j) => SrsItem(
    // itemId：必填字段，若缺失则置 null（由 SrsItem 构造函数的 required 校验捕获）
    itemId: j['itemId'],
    // type：可选字段，缺失时默认 'flashcard'（向后兼容仅闪卡版本的旧存储数据）
    type: j['type'] ?? 'flashcard',
    // ef：三层安全转型链——取 Map 值 → as num?（安全转型） → toDouble → 兜底 2.5
    ef: (j['ef'] as num?)?.toDouble() ?? 2.5,
    // reps：可选 int，缺失时默认 0（视为新条目）
    reps: j['reps'] ?? 0,
    // interval：可选 int，缺失时默认 1（首次复习间隔 1 天）
    interval: j['interval'] ?? 1,
    // nextReviewAt：可选 int，缺失时默认 0（未安排复习，调度器视为立即可复习）
    nextReviewAt: j['nextReviewAt'] ?? 0,
    // errors：可选 int，缺失时默认 0（无错误记录）
    errors: j['errors'] ?? 0,
    // createdAt：可选 int，缺失时默认 0（创建时间未知）
    createdAt: j['createdAt'] ?? 0,
    // lastReviewedAt：可选 int，缺失时默认 0（从未被复习）
    lastReviewedAt: j['lastReviewedAt'] ?? 0,
  );
}
