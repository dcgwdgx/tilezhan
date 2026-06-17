/// 闪卡 quiz 状态管理 — 通过 Riverpod StateNotifier 驱
/// 动单局答题流程：加载牌池、出题、判对错、助记联想及下一题推进。
///
/// 核心职责：
/// - 从 [TileRepository] 加载全量牌数据并按花色 / 风箭过滤
/// - 为每道题预构建干扰项 options，避免 UI 重建时闪烁
/// - 管理答题状态机：答题中 → 查看助记 → 下一题 → 结算
/// - 通过 [flashcardQuizProvider] 暴露给 Widget 层消费

// =============================================================================
// 标准库 & 第三方依赖
// =============================================================================

/// Dart 数学工具：提供 `min` / `max` 等函数以及随机数发生器供 shuffle 使用。
import 'dart:math';

/// Riverpod 状态管理框架：提供 [StateNotifierProvider] 用于将
/// [FlashcardQuizNotifier] 暴露为全局可观察的状态源。
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 牌数据模型：定义 [TileModel]、[TileSuit] 等核心数据结构，
/// 整个闪卡模块的领域对象均基于此模型。
import '../../../shared/models/tile_model.dart';

/// 牌数据仓库：封装牌数据的加载、过滤与干扰项生成逻辑，
/// [FlashcardQuizNotifier] 通过此仓库获取所有原始牌数据。
import '../../../shared/data/tile_repository.dart';

/// 全局牌数据 Provider：暴露 [tileRepositoryProvider]，
/// 确保整个应用共享同一个 [TileRepository] 实例。
import '../../../core/providers/tile_data_provider.dart';

/// 闪卡状态定义：包含 [FlashcardQuizState] 数据类，
/// 封装单局答题过程中的所有可变状态字段。
import 'flashcard_state.dart';

// =============================================================================
// 全局 Provider 定义
// =============================================================================

/// 闪卡 quiz 全局 Provider，由 Riverpod 自动管理生命周期。
///
/// 使用 `autoDispose` 修饰符：当所有监听此 Provider 的 Widget
/// 从 Widget 树中移除时，Riverpod 自动调用 [FlashcardQuizNotifier]
/// 的 `dispose` 并释放其持有的状态内存，避免离开闪卡页面后内存常驻。
///
/// 使用方式：
/// ```dart
/// final quizState = ref.watch(flashcardQuizProvider);
/// final quizNotifier = ref.read(flashcardQuizProvider.notifier);
/// ```
final flashcardQuizProvider =
    StateNotifierProvider.autoDispose<FlashcardQuizNotifier, FlashcardQuizState>(
        (ref) => FlashcardQuizNotifier(ref.read(tileRepositoryProvider)));

// =============================================================================
// 状态控制器
// =============================================================================

/// 闪卡答题流程的状态控制器。
///
/// 持有 [TileRepository] 引用，负责初始化牌队列、生成干扰选项、
/// 记录对/错计数、切换助记展示及推进到下一题。
/// 所有状态变更通过不可变 [FlashcardQuizState] 完成，
/// 确保 Riverpod 的 rebuild 粒度精确。
///
/// 状态机流转（由各公开方法驱动）：
/// ```
/// initQuiz / restart  →  [答题中: isAnswering=false, isShowingMnemonic=false]
/// submitAnswer       →  [已作答: isAnswering=true,  isShowingMnemonic=false]
/// showMnemonic       →  [查看助记: isAnswering=true,  isShowingMnemonic=true]
/// nextCard           →  [答题中: isAnswering=false, isShowingMnemonic=false]（循环）
///                     或 [结算: currentIndex >= totalCount]
/// ```
class FlashcardQuizNotifier extends StateNotifier<FlashcardQuizState> {
  // ---------------------------------------------------------------------------
  // 私有字段
  // ---------------------------------------------------------------------------

  /// 牌数据仓库引用，用于加载全量牌数据和生成干扰项。
  /// 由构造函数注入，确保可测试性（可替换为 mock 实现）。
  final TileRepository _repo;

  /// 全量牌数据缓存。
  ///
  /// 在 [initQuiz] 中通过 `_repo.loadAllTiles()` 一次性加载，
  /// 后续的[过滤]、[getDistractors] 等操作均以此缓存为基础，
  /// 避免重复 I/O 或网络请求。
  List<TileModel> _allTiles = [];

  // ---------------------------------------------------------------------------
  // 构造函数
  // ---------------------------------------------------------------------------

  /// 创建闪卡答题状态控制器。
  ///
  /// [repo]：牌数据仓库实例，通常由 [tileRepositoryProvider] 提供。
  /// 初始化时传入 [FlashcardQuizState] 的默认常量构造，
  /// 此时所有字段均为初始值（空队列、计数归零、未开始答题）。
  FlashcardQuizNotifier(this._repo) : super(const FlashcardQuizState());

  // ---------------------------------------------------------------------------
  // 私有方法
  // ---------------------------------------------------------------------------

  /// 为指定正确答案牌预构建一道题的全部选项（含干扰项 + 正确项）。
  ///
  /// 工作流程：
  /// 1. 调用 `_repo.getDistractors` 从全量牌缓存中取 3 张干扰牌；
  /// 2. 将干扰牌与正确牌合并为一个列表；
  /// 3. 对整个列表执行 `shuffle`，打乱顺序以保证正确项位置随机。
  ///
  /// 此方法在 [initQuiz] 和 [nextCard] 中提前调用，
  /// 确保 [FlashcardQuizState.options] 在 Widget build 时已就绪，
  /// 避免 UI 重建时选项列表闪烁或瞬变。
  ///
  /// 参数：
  /// - [correct]：当前题目的正确答案牌。
  ///
  /// 返回：
  /// - 长度为 4 的 [TileModel] 列表，其中恰含 1 张正确牌和 3 张干扰牌，
  ///   顺序已随机打乱。
  List<TileModel> _buildOptions(TileModel correct) {
    final distractors = _repo.getDistractors(correct, _allTiles, 3);
    final opts = [...distractors, correct]..shuffle();
    return opts;
  }

  // ---------------------------------------------------------------------------
  // 公开方法 — 答题流程控制
  // ---------------------------------------------------------------------------

  /// 初始化一局闪卡 quiz。
  ///
  /// 完整流程：
  /// 1. 从仓库加载全量牌数据到 [_allTiles] 缓存；
  /// 2. 按 [suite] 参数过滤牌：`'all'` 不过滤、`'honor'` 仅保留风箭牌、
  ///    其他值按花色名 `TileSuit.name` 精确匹配；
  /// 3. 对过滤后的牌列表 shuffle 随机打乱；
  /// 4. 截取前 [count] 张作为本局答题队列；
  /// 5. 为队列首张牌预构建选项列表；
  /// 6. 产出新的 [FlashcardQuizState] 替换当前状态。
  ///
  /// 参数：
  /// - [suite]：花色过滤条件，默认 `'all'`（全部花色）。
  ///   可选值：`'all'` | `'honor'`（风牌 + 箭牌）| `'wan'` | `'tong'` | `'tiao'`。
  /// - [count]：本局题目数量，默认 10。当过滤后可用牌数不足时自动
  ///   取较小值。
  Future<void> initQuiz({String suite = 'all', int count = 10}) async {
    // 1. 加载全量牌数据到内存缓存
    _allTiles = await _repo.loadAllTiles();

    // 2. 按花色过滤
    final filtered = suite == 'all'
        ? _allTiles
        : suite == 'honor'
            ? _allTiles
                .where((t) => t.suit == TileSuit.wind || t.suit == TileSuit.dragon)
                .toList()
            : _allTiles.where((t) => t.suit.name == suite).toList();

    // 3. 随机打乱过滤后的牌列表
    final shuffled = List<TileModel>.from(filtered)..shuffle();

    // 4. 截取答题队列（不超过可用牌数）
    final queue = shuffled.take(min(count, shuffled.length)).toList();

    // 5. 为第一题预构建选项
    final options = queue.isNotEmpty ? _buildOptions(queue[0]) : <TileModel>[];

    // 6. 产出初始状态
    state = FlashcardQuizState(
      queue: queue,
      currentIndex: 0,
      suite: suite,
      options: options,
    );
  }

  /// 为给定正确牌获取干扰项列表（不含正确牌本身）。
  ///
  /// 此方法是 [_buildOptions] 的公开精简版，供 UI 层在需要动态
  /// 获取干扰项（如助记对比展示）时调用。
  ///
  /// 参数：
  /// - [correct]：正确答案牌。
  ///
  /// 返回：
  /// - 长度固定为 3 的 [TileModel] 列表，均为干扰牌。
  List<TileModel> getDistractors(TileModel correct) {
    return _repo.getDistractors(correct, _allTiles, 3);
  }

  /// 提交当前题目的答案。
  ///
  /// 行为：
  /// - 若当前已在 "已作答" 状态（[FlashcardQuizState.isAnswering] 为
  ///   `true`），则直接返回，防止重复提交。
  /// - 将 [isAnswering] 标记为 `true`。
  /// - 根据 [isCorrect] 递增 [correctCount] 或 [wrongCount]。
  /// - 通过 [lastCorrectId] / [lastWrongId] 记录本次作答结果，
  ///   供 UI 层高亮正确/错误选项。
  ///
  /// 参数：
  /// - [isCorrect]：用户选择的选项是否为正确答案。
  void submitAnswer(bool isCorrect) {
    // 已作答状态下不允许重复提交
    if (state.isAnswering) return;

    state = state.copyWith(
      isAnswering: true,
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      wrongCount: isCorrect ? state.wrongCount : state.wrongCount + 1,
      lastCorrectId: isCorrect ? state.currentTile?.id : null,
      lastWrongId: isCorrect ? null : state.currentTile?.id,
    );
  }

  /// 展示当前题目的助记信息。
  ///
  /// 前置条件：必须已作答（[isAnswering] 为 `true`），否则调用无效。
  /// 效果：将 [isShowingMnemonic] 设为 `true`，
  /// UI 层据此展示当前牌的 slogan / 描述等助记内容。
  void showMnemonic() {
    if (!state.isAnswering) return;
    state = state.copyWith(isShowingMnemonic: true);
  }

  /// 隐藏当前题目的助记信息。
  ///
  /// 无前置条件，可在任意时刻调用。效果：将 [isShowingMnemonic] 设为
  /// `false`，UI 层恢复为普通作答后视图。
  void hideMnemonic() {
    state = state.copyWith(isShowingMnemonic: false);
  }

  /// 推进到下一题。
  ///
  /// 两种分支：
  /// - **还有下一题**（`nextIdx < totalCount`）：为下一题的牌预构建
  ///   新的选项列表，重置 [isAnswering]、[isShowingMnemonic]、
  ///   [lastCorrectId]、[lastWrongId] 为初始值。
  /// - **已答完最后一题**（`nextIdx >= totalCount`）：仅更新
  ///   [currentIndex]，不构建新选项。此时 UI 层检测到
  ///   `currentIndex >= totalCount` 后应展示结算界面。
  void nextCard() {
    final nextIdx = state.currentIndex + 1;
    if (nextIdx >= state.totalCount) {
      // 本局结束，仅推进索引，UI 层据此展示结算
      state = state.copyWith(currentIndex: nextIdx);
    } else {
      // 为下一题预构建选项，并重置作答状态
      final nextOptions = _buildOptions(state.queue[nextIdx]);
      state = state.copyWith(
        currentIndex: nextIdx,
        isAnswering: false,
        isShowingMnemonic: false,
        lastCorrectId: null,
        lastWrongId: null,
        options: nextOptions,
      );
    }
  }

  /// 重新开始当前 quiz。
  ///
  /// 行为：对当前队列（保留原花色过滤范围）重新 shuffle 打乱，
  /// 重置所有答题进度（对错计数归零），回到第一题。
  ///
  /// 使用场景：用户在结算界面点击 "再来一局" 时调用。
  void restart() {
    final shuffled = List<TileModel>.from(state.queue)..shuffle();
    final options =
        shuffled.isNotEmpty ? _buildOptions(shuffled[0]) : <TileModel>[];
    state = FlashcardQuizState(
      queue: shuffled,
      suite: state.suite,
      options: options,
    );
  }
}
