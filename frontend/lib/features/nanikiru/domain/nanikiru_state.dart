/// 何切（打哪张）谜题的不可变状态模型。
///
/// 定义一个何切谜题回合的核心领域类型：
/// - [NaniKiruPhase]：阶段驱动的生命周期枚举
/// - [NaniKiruState]：手工打造的不可变状态类，承载谜题从选择、
///   动画到反馈阶段的全部数据
///
/// 设计意图：
/// 整个何切功能的状态流转遵循严格的单向数据流原则。外部只能通过
/// [NaniKiruState.copyWith] 创建新状态，永远不直接修改字段。
/// 这种不可变设计使得状态变更可预测、可追溯，适合与 Riverpod /
/// BLoC 等状态管理方案配合使用。
import '../../../shared/models/tile_model.dart';

/// 何切谜题回合的生命周期阶段。
///
/// 一个完整的何切回合按顺序经历以下四个阶段：
///
/// * [ready] — 谜题已加载完毕，等待用户点击手牌中的某张牌。
///   此时倒计时开始走动，UI 展示 14 张手牌（13 张原有 + 1 张摸进），
///   所有牌处于可交互状态（无高亮、无禁用）。
///
/// * [selecting] — 用户已点击一张候选牌，UI 高亮该牌并等待确认。
///   此阶段用于防止误触：用户需要二次确认（例如再次点击同一张牌
///   或点击"确定"按钮），确认后阶段推进至 [animating]。
///
/// * [animating] — 弃牌动画播放中。被选中的牌执行打出/翻转动画，
///   此阶段通常持续 300-500ms，期间禁止用户交互。动画结束后
///   自动推进至 [feedback]。
///
/// * [feedback] — 展示结果：正确/错误标记、听牌分析（有效进张数、
///   进张种类、具体进张牌列表）、SRS 调度信息等。用户点击"下一题"
///   后，外部状态管理层创建全新的 [NaniKiruState] 实例进入下一回合。
enum NaniKiruPhase { ready, selecting, animating, feedback }

/// 单个何切谜题回合的不可变状态。
///
/// ## 数据构成
///
/// 此状态对象承载一个回合完整生命周期所需的全部数据，分为三类：
///
/// - **谜题定义数据**（题目本身，生命周期内不变）：
///   [handTiles]、[drawnTileId]、[correctDiscardId]、[puzzleId]
///
/// - **用户交互数据**（随阶段推进而更新）：
///   [selectedTileId]、[phase]、[isPerfect]
///
/// - **倒计时与反馈数据**（在特定阶段填充）：
///   [countdownValue]、[ukeireCount]、[ukeireTypes]、[ukeireTiles]
///
/// ## 不可变设计
///
/// 所有字段均为 `final`，类本身没有公开的 setter 方法。创建新状态
/// 的唯一途径是调用 [copyWith]，它返回一个字段级浅拷贝的新实例。
/// 这种模式源自函数式编程中的"不可变数据 + 透镜更新"思想，
/// 在 Flutter 中广泛使用，因为：
/// - 状态变更可被精确追踪（旧状态 vs 新状态）
/// - 与 `==` 运算符和 `Equatable` 配合时可做高效 diff
/// - 避免多组件并发修改同一状态导致的竞态问题
///
/// ## 使用示例
///
/// ```dart
/// // 创建初始状态（准备阶段）
/// final state = NaniKiruState(
///   handTiles: tiles,
///   drawnTileId: '1m',
///   correctDiscardId: '5p',
///   puzzleId: 'puzzle_001',
/// );
///
/// // 用户选择一张牌 → 进入选择确认阶段
/// final selecting = state.copyWith(
///   selectedTileId: '5p',
///   phase: NaniKiruPhase.selecting,
/// );
///
/// // 动画播放 → 进入反馈阶段，同时填充听牌数据
/// final feedback = selecting.copyWith(
///   phase: NaniKiruPhase.animating,
/// );
/// // 动画结束后
/// final result = feedback.copyWith(
///   phase: NaniKiruPhase.feedback,
///   isPerfect: true,
///   ukeireCount: 12,
///   ukeireTypes: 4,
///   ukeireTiles: ['1m', '4m', '7m', '2p'],
/// );
/// ```
class NaniKiruState {
  /// 玩家手牌（摸牌前），共 13 张。
  ///
  /// 这些牌与 [drawnTileId] 组合成 14 张待切手牌。
  /// 列表中每张牌在 UI 中以牌面形式渲染，排列顺序由 UI 层决定
  /// （通常按万/筒/索/字分类、同花色按数字升序）。
  ///
  /// 默认值为空列表，表示尚未加载谜题数据。
  final List<TileModel> handTiles;

  /// 刚摸进的牌的 ID（如 `'1m'`、`'5p'`、`'7z'`）。
  ///
  /// 在 UI 中，这张牌通常独立展示在手牌最右侧（与 13 张 [handTiles]
  /// 用视觉间距隔开），以模拟真实麻将中"摸牌后放在手牌最右侧"的习惯。
  ///
  /// 此 ID 用于：① 区分哪张是摸进的牌（UI 高亮提示）；② 确保
  /// 摸进的牌不能被选为弃牌目标（大多数何切规则不允许摸切）。
  ///
  /// 默认值为空字符串，表示尚未摸牌。
  final String drawnTileId;

  /// 本谜题的正确弃牌 ID。
  ///
  /// 由谜题数据源（JSON / 数据库 / 算法生成）提供，代表通向最大
  /// 有效进张数（或最优听牌形）的那一张弃牌。在 [feedback] 阶段，
  /// 系统将此 ID 与 [selectedTileId] 比较以判定 [isPerfect]。
  ///
  /// 注意：部分高级谜题可能有多个等价最优解（多张弃牌进张数相同），
  /// 此时 [correctDiscardId] 存储主推荐解，而 UI 可能在反馈中展示
  /// 所有等价解。
  final String correctDiscardId;

  /// 用户当前选中的牌的 ID，未选择时为 `null`。
  ///
  /// - 在 [NaniKiruPhase.ready] 阶段：始终为 `null`
  /// - 在 [NaniKiruPhase.selecting] 阶段：存储用户点击的牌 ID，
  ///   UI 据此高亮该牌
  /// - 在 [NaniKiruPhase.animating] 阶段：保持选择不变，动画以此牌
  ///   为目标
  /// - 在 [NaniKiruPhase.feedback] 阶段：即为用户的最终答案
  ///
  /// 可空设计允许用 `null` 表示"未做选择"的语义，
  /// 避免用空字符串 `''` 或魔法值带来的歧义。
  final String? selectedTileId;

  /// 当前谜题回合所处的生命周期阶段。
  ///
  /// 详见 [NaniKiruPhase] 枚举中各阶段的说明。阶段流转由外部状态
  /// 管理层（如 Riverpod Notifier / BLoC）控制，本状态类仅存储当前阶段值。
  ///
  /// 默认值为 [NaniKiruPhase.ready]（谜题已加载，等待用户操作）。
  final NaniKiruPhase phase;

  /// 计时模式下的剩余倒计时秒数。
  ///
  /// 仅在启用计时模式时有意义。取值范围通常为 `[0.0, 10.0]`（10 秒
  /// 倒计时），由 UI 层的动画控制器驱动递减。倒计时归零时，
  /// 即使玩家未做出选择，外部管理层也应强制推进至 [feedback] 阶段
  /// 并将选择判为错误。
  ///
  /// 默认值为 `10.0` 秒，可在构造函数中覆盖。
  final double countdownValue;

  /// 用户最终选择是否匹配正确答案（即是否为完美解答）。
  ///
  /// 在 [feedback] 阶段由外部管理层判定：若 [selectedTileId] 等于
  /// [correctDiscardId] 则为 `true`，否则为 `false`。
  /// 非反馈阶段此字段无意义（默认为 `false`）。
  ///
  /// 此字段命名故意避开了 `isCorrect`，因为何切谜题中存在"虽然不是
  /// 最优解但也不算大错"的中间地带（未来可能扩展为枚举：
  /// perfect / suboptimal / wrong）。
  final bool isPerfect;

  /// 有效进张数（受け入れ枚数 / uke-ire count）。
  ///
  /// 正确弃牌后，摸到能让你听牌（或和牌）的牌的总张数。
  /// 例如听三面待ち（如 3-6-9 万）时，假设每种牌剩余 4 张，
  /// 则有效进张数为 3 × 4 = 12 张。
  ///
  /// 此字段在 [feedback] 阶段填充，其他阶段为 `null`。
  /// 可空设计使得 UI 层能够通过 `if (state.ukeireCount != null)`
  /// 判断是否应该展示进张分析面板。
  final int? ukeireCount;

  /// 有效进张的种类数（受け入れの種類数）。
  ///
  /// 即能让你听牌的不同牌面（不计每种牌的张数）的数量。
  /// 例如听三面（3m、6m、9m）时，种类数为 3。
  /// 此值用于计算听牌面数和生成分析文案（如"三面听"）。
  ///
  /// 在 [feedback] 阶段填充，其他阶段为 `null`。
  final int? ukeireTypes;

  /// 有效进张的具体牌 ID 列表。
  ///
  /// 列出所有能让手牌听牌（或和牌）的牌面 ID，例如：
  /// `['1m', '4m', '7m', '2p', '5p', '8p']`。
  /// UI 反馈面板通常将列表中的每张牌以小图标网格形式展示，
  /// 并用颜色区分"已见牌"（已在手牌/河底中）和"未见牌"。
  ///
  /// 在 [feedback] 阶段填充，其他阶段为 `null`。
  final List<String>? ukeireTiles;

  /// 持久化谜题标识符，用于 SRS（间隔重复系统）调度和统计追踪。
  ///
  /// 每个谜题在数据库中有唯一 ID，SRS 算法据此记录用户对该谜题的
  /// 掌握程度（熟练度等级、下次复习时间、历史正确率等）。
  ///
  /// 此 ID 在整个谜题生命周期内不变，即使 [handTiles] 等数据因
  /// 算法参数调整而更新，[puzzleId] 仍保持不变以便跨版本追踪。
  ///
  /// 默认值为空字符串，表示尚未关联持久化谜题记录。
  final String puzzleId;

  /// 创建一个何切谜题回合的不可变状态。
  ///
  /// 所有参数均为可选的命名参数，默认值对应"刚加载、等待开始"的
  /// 初始状态：
  /// - 手牌为空（等待加载）
  /// - 阶段为 [NaniKiruPhase.ready]
  /// - 倒计时 10 秒
  /// - 无选择、无结果、无听牌数据
  ///
  /// 构造函数声明为 `const`，允许编译时常量实例化（在 `const` 上下文
  /// 中可作为组件的默认参数或 Provider 的初始值）。
  const NaniKiruState({
    this.handTiles = const [],
    this.drawnTileId = '',
    this.correctDiscardId = '',
    this.selectedTileId,
    this.phase = NaniKiruPhase.ready,
    this.countdownValue = 10.0,
    this.isPerfect = false,
    this.ukeireCount,
    this.ukeireTypes,
    this.ukeireTiles,
    this.puzzleId = '',
  });

  /// 谜题回合是否已经结束（即是否应展示反馈覆盖层）。
  ///
  /// 当 [phase] 为 [NaniKiruPhase.feedback] 时返回 `true`。
  /// 这是一个派生属性（computed property），不存储额外数据，
  /// 仅提供语义化的查询接口。
  ///
  /// 典型用法：
  /// ```dart
  /// if (state.isFinished) {
  ///   // 展示结果面板
  ///   showFeedbackOverlay(state);
  /// }
  /// ```
  ///
  /// 等价于 `state.phase == NaniKiruPhase.feedback`，
  /// 但 `isFinished` 更具可读性，且对外隐藏了阶段枚举的实现细节。
  bool get isFinished => phase == NaniKiruPhase.feedback;

  /// 返回一个新的 [NaniKiruState]，用传入的参数替换对应字段。
  ///
  /// 这是修改状态的**唯一**方式 —— [NaniKiruState] 自身没有任何
  /// 可变 setter，所有字段均为 `final`。
  ///
  /// ## 参数
  ///
  /// 每个参数都是可选的；未传入的参数保持当前值不变。传入 `null`
  /// 的语义因字段类型而不同：
  /// - 对于不可空字段（如 [handTiles]、[phase]），传入 `null` 表示
  ///   "保持原值"（因为无法用 `null` 覆盖不可空字段）
  /// - 对于可空字段（如 [selectedTileId]、[ukeireCount]），传入
  ///   **非 null** 值会覆盖，传入 `null` 才表示"保持原值"。
  ///   Dart 的 `??` 运算符天然实现了这一语义。
  ///
  /// ## 返回值
  ///
  /// 返回新的 [NaniKiruState] 实例。如果所有参数均为 `null`（即
  /// 未传入任何参数），则返回一个字段值与当前实例完全相同的新实例
  /// （浅等价，但引用不同）。
  ///
  /// ## 设计考量
  ///
  /// `copyWith` 的命名参数设计刻意与构造函数的参数列表保持一致，
  /// 降低学习成本和维护负担。这是 Flutter 社区广泛采用的模式，
  /// 在 BLoC、Riverpod、Provider 等状态管理方案中均有大量用例。
  ///
  /// ## 性能说明
  ///
  /// `copyWith` 执行的是浅拷贝（shallow copy）：列表字段（如
  /// [handTiles]、[ukeireTiles]）的引用被直接传递，不会创建
  /// 新的列表实例。如果需要深度拷贝列表内容，调用方应自行处理。
  /// 在实践中，由于 [handTiles] 中的 [TileModel] 本身也是不可变的，
  /// 浅拷贝通常足够安全。
  NaniKiruState copyWith({
    List<TileModel>? handTiles,
    String? drawnTileId,
    String? correctDiscardId,
    String? selectedTileId,
    NaniKiruPhase? phase,
    double? countdownValue,
    bool? isPerfect,
    int? ukeireCount,
    int? ukeireTypes,
    List<String>? ukeireTiles,
    String? puzzleId,
  }) {
    return NaniKiruState(
      handTiles: handTiles ?? this.handTiles,
      drawnTileId: drawnTileId ?? this.drawnTileId,
      correctDiscardId: correctDiscardId ?? this.correctDiscardId,
      selectedTileId: selectedTileId ?? this.selectedTileId,
      phase: phase ?? this.phase,
      countdownValue: countdownValue ?? this.countdownValue,
      isPerfect: isPerfect ?? this.isPerfect,
      ukeireCount: ukeireCount ?? this.ukeireCount,
      ukeireTypes: ukeireTypes ?? this.ukeireTypes,
      ukeireTiles: ukeireTiles ?? this.ukeireTiles,
      puzzleId: puzzleId ?? this.puzzleId,
    );
  }
}
