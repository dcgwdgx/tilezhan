/// 闪卡测验会话的不可变状态模型。
///
/// 追踪卡牌匹配测验的完整生命周期：一组 [TileModel] 卡牌队列、
/// 用户在队列中的进度、正确/错误计数、答案动画标志以及助记词显示开关。
/// 设计为仅通过 [FlashcardQuizState.copyWith] 进行更新，确保调用方始终获取全新快照。
import '../../../shared/models/tile_model.dart';

/// 单次闪卡测验运行的完整不可变状态。
///
/// 每个实例捕获一个固定的时间快照：当前激活哪张卡、已答对和答错多少题、
/// 助记词辅助面板是否可见，以及当前卡牌的预洗牌 [options] 选项列表。
/// 本类不提供任何公共 setter；调用方通过 [copyWith] 派生下一个状态帧。
class FlashcardQuizState {
  /// 测验中剩余卡牌的有序列表（队列）。
  final List<TileModel> queue;

  /// 当前展示给用户的卡牌在队列中的零基索引。
  final int currentIndex;

  /// 截至目前答对的卡牌累计数量。
  final int correctCount;

  /// 截至目前答错的卡牌累计数量。
  final int wrongCount;

  /// 是否处于等待用户为当前卡牌选择答案的状态。
  final bool isAnswering;

  /// 助记词辅助面板当前是否展开显示。
  final bool isShowingMnemonic;

  /// 最近一次答对的卡牌 ID，无则为 `null`。
  ///
  /// 供 UI 驱动简短的答题成功反馈动画使用，
  /// 无需额外引入基于定时器的标志。
  final String? lastCorrectId;

  /// 最近一次答错的卡牌 ID，无则为 `null`。
  ///
  /// 与 [lastCorrectId] 配合使用，驱动答题错误反馈动画。
  final String? lastWrongId;

  /// 当前测验所限定的卡牌套系（分类），`'all'` 表示包含所有可用卡牌。
  final String suite;
  /// 当前卡牌的预洗牌选项列表（4 项）。
  final List<TileModel> options;

  /// 创建一个测验状态的 const 快照。
  ///
  /// 所有参数均为可选的，且具有合理的默认值，
  /// 因此调用方可以直接通过 `FlashcardQuizState()` 构造测验前的初始状态。
  const FlashcardQuizState({
    this.queue = const [],
    this.currentIndex = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.isAnswering = false,
    this.isShowingMnemonic = false,
    this.lastCorrectId,
    this.lastWrongId,
    this.suite = 'all',
    this.options = const [],
  });

  /// 用户当前正在作答的卡牌；如果测验已结束或队列为空则返回 `null`。
  TileModel? get currentTile =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  /// 测验队列中的卡牌总数。
  int get totalCount => queue.length;

  /// 队列中的每一张卡牌是否都已被展示过（即测验是否已完成）。
  bool get isFinished => currentIndex >= totalCount;

  /// 以 [0, 1] 区间的小数表示的队列进度。
  double get progress => totalCount > 0 ? currentIndex / totalCount : 0;

  /// 返回一个新的 [FlashcardQuizState]，其中指定字段已替换为新值。
  ///
  /// 所有参数均为可选的；未传入的参数将保留当前值不变。
  /// 这是变更测验状态的唯一途径——本类不提供任何公共 setter。
  FlashcardQuizState copyWith({
    List<TileModel>? queue,
    int? currentIndex,
    int? correctCount,
    int? wrongCount,
    bool? isAnswering,
    bool? isShowingMnemonic,
    String? lastCorrectId,
    String? lastWrongId,
    String? suite,
    List<TileModel>? options,
  }) {
    return FlashcardQuizState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      isAnswering: isAnswering ?? this.isAnswering,
      isShowingMnemonic: isShowingMnemonic ?? this.isShowingMnemonic,
      lastCorrectId: lastCorrectId,
      lastWrongId: lastWrongId,
      suite: suite ?? this.suite,
      options: options ?? this.options,
    );
  }
}
