/// 何切 (Nanikiru) 谜题状态管理模块。
///
/// 提供基于 Riverpod 的 [StateNotifierProvider] 和 [NanikiruNotifier]，
/// 负责谜题的生成、倒计时、选牌交互和判定反馈。
/// 难度随用户 ELO 自适应，由 [DifficultyScorer] 和 [PuzzleGenerator] 协作完成。
///
/// ## 架构概览
///
/// ```
/// nanikiruProvider (Riverpod)
///   └── NanikiruNotifier (StateNotifier)
///         ├── _repo       : TileRepository — 牌数据源
///         ├── _ref        : Ref — 读取其他 Provider 的钩子
///         ├── _allTiles   : 全量牌列表缓存，避免重复加载
///         └── _puzzleCounter : 单调计数，生成唯一谜题 ID
/// ```
///
/// ## 状态流转
///
///   ready → selecting → feedback → (nextPuzzle) → ready → …
///                            │
///                            ├── 正确 (isPerfect = true)
///                            └── 错误 (isPerfect = false, 包含超时/跳过)
///
/// ## 难度自适应
///
/// 每次 [initPuzzle] 都会读取持久化的用户 ELO 分数，通过 [DifficultyScorer.targetRange]
/// 换算为难度区间，再交由 [PuzzleGenerator.generate] 生成与之匹配的谜题。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/data/tile_repository.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/storage/storage_service.dart';
import 'nanikiru_state.dart';
import 'puzzle_generator.dart';
import 'difficulty_scorer.dart';

/// 何切谜题的全局状态提供者，自动释放以节省内存。
///
/// 通过 [StateNotifierProvider.autoDispose] 创建，当所有监听者取消订阅时
/// 自动销毁 [NanikiruNotifier] 实例及其持有的牌数据缓存，避免内存泄漏。
///
/// 典型用法：
/// ```dart
/// final state = ref.watch(nanikiruProvider);
/// ref.read(nanikiruProvider.notifier).initPuzzle();
/// ```
final nanikiruProvider =
    StateNotifierProvider.autoDispose<NanikiruNotifier, NaniKiruState>(
        (ref) => NanikiruNotifier(ref.read(tileRepositoryProvider), ref));

/// 管理何切谜题的完整生命周期。
///
/// 职责包括：
/// - 加载全量牌库并根据用户 ELO 生成自适应难度的谜题
/// - 处理倒计时 tick、选牌 tap、确认弃牌及手牌排序
/// - 控制谜题状态流转：准备 → 选择中 → 反馈 → 下一题
///
/// [NanikiruNotifier] 是此功能模块的核心状态机，所有 UI 交互最终都通过
/// 本类的方法驱动状态变更。外部只需监听 [state] 即可响应式更新界面。
class NanikiruNotifier extends StateNotifier<NaniKiruState> {
  /// 牌数据仓库，提供按 ID 查找牌模型的能力。
  ///
  /// 在构造函数中注入，由 [tileRepositoryProvider] 提供实例。
  final TileRepository _repo;

  /// Riverpod 的 [Ref] 句柄，用于在 [initPuzzle] 中读取其他 Provider
  ///（如 [storageServiceProvider]）而不产生持久订阅。
  final Ref _ref;

  /// 全量牌列表的内存缓存。
  ///
  /// 在 [initPuzzle] 中首次加载后缓存，后续谜题生成直接从缓存按 ID 查找，
  /// 避免重复 I/O。生命周期与 [NanikiruNotifier] 实例一致。
  List<TileModel> _allTiles = [];

  /// 谜题序号计数器，自增生成唯一谜题标识符。
  ///
  /// 每次 [initPuzzle] 调用递增一次，用于构造 `nanikiru_N` 格式的 [NaniKiruState.puzzleId]，
  /// 便于日志追踪和统计去重。
  int _puzzleCounter = 0;

  /// 构造一个 [NanikiruNotifier] 实例。
  ///
  /// [repo]  牌数据仓库，由 Riverpod 通过 [tileRepositoryProvider] 自动注入。
  /// [ref]   Riverpod 的 [Ref]，保留引用以便惰性读取其他 Provider。
  ///
  /// 初始状态为 [NaniKiruState] 的默认构造（空手牌、ready 阶段、10 秒倒计时）。
  NanikiruNotifier(this._repo, this._ref) : super(const NaniKiruState());

  /// 初始化（或重新生成）一道何切谜题。
  ///
  /// ## 执行流程
  ///
  /// 1. **加载牌库** — 从 [_repo] 加载全量牌数据并缓存至 [_allTiles]。
  /// 2. **读取用户 ELO** — 通过 [_ref] 惰性读取 [StorageService] 中持久化的
  ///    ELO 分数（键名 [StorageService.kElo]），默认 1000。
  /// 3. **计算目标难度** — 调用 [DifficultyScorer.targetRange] 将 ELO 映射为
  ///    难度区间。
  /// 4. **生成谜题** — 调用 [PuzzleGenerator.generate] 生成符合目标难度的
  ///    谜题数据（13 张手牌 + 摸牌 + 正确弃牌 + 受入信息）。
  /// 5. **组装手牌** — 按 ID 从缓存中取出 [TileModel] 实例，14 张手牌 =
  ///    13 张原始手牌 + 摸牌（固定在末尾）。
  /// 6. **更新状态** — 构造新的 [NaniKiruState]，阶段设为 [NaniKiruPhase.ready]，
  ///    倒计时重置为 10.0 秒，puzzleId 递增。
  ///
  /// ## 异步特性
  ///
  /// 首次调用会触发 I/O 加载牌库（[TileRepository.loadAllTiles]），
  /// 后续调用复用缓存，为同步操作。
  Future<void> initPuzzle() async {
    _allTiles = await _repo.loadAllTiles();

    // Generate puzzle matching user ELO difficulty
    final storage = _ref.read(storageServiceProvider).valueOrNull;
    final userElo = storage?.getInt(StorageService.kElo) ?? 1000;
    final target = DifficultyScorer.targetRange(userElo);
    final puzzle = PuzzleGenerator.generate(targetDifficulty: target);
    final handTiles = puzzle.hand13Ids
        .map((id) => _repo.getById(id, _allTiles))
        .whereType<TileModel>()
        .toList();
    final drawnTile = _repo.getById(puzzle.drawnTileId, _allTiles);

    _puzzleCounter++;
    final puzzleId = 'nanikiru_$_puzzleCounter';

    state = NaniKiruState(
      handTiles: [...handTiles, if (drawnTile != null) drawnTile],
      drawnTileId: puzzle.drawnTileId,
      correctDiscardId: puzzle.correctDiscardId,
      phase: NaniKiruPhase.ready,
      countdownValue: 10.0,
      ukeireCount: puzzle.ukeireCount,
      ukeireTypes: puzzle.ukeireTypes,
      ukeireTiles: puzzle.ukeireTileIds,
      puzzleId: puzzleId,
    );
  }

  /// 倒计时 tick 处理，每帧由游戏循环调用。
  ///
  /// [delta] 自上一帧以来的时间增量（秒），由调用方（通常为动画控制器或
  /// Ticker）提供。
  ///
  /// ## 行为
  ///
  /// - 如果当前谜题已结束（[NaniKiruState.isFinished]），忽略本次 tick。
  /// - 将 [NaniKiruState.countdownValue] 减去 [delta] 并钳制在 [0.0, 10.0] 区间。
  /// - 若倒计时归零且谜题未结束，自动调用 [confirmDiscard] 以当前选中牌
  ///   （若无选中则传空字符串）提交弃牌判定。
  ///
  /// ## 超时判定语义
  ///
  /// 超时视为"未选出正确牌"，等同于答错。由 [confirmDiscard] 将 `isPerfect`
  /// 设为 `false`，UI 层据此展示错误反馈。
  void tickCountdown(double delta) {
    if (state.isFinished) return;
    final newValue = (state.countdownValue - delta).clamp(0.0, 10.0);
    state = state.copyWith(countdownValue: newValue);
    if (newValue <= 0 && !state.isFinished) {
      confirmDiscard(state.selectedTileId ?? '');
    }
  }

  /// 处理玩家点击手牌的事件。
  ///
  /// [tileId] 被点击的牌的 ID。
  ///
  /// ## 交互逻辑（两段式选牌）
  ///
  /// - **非选择阶段**（非 `ready` 且非 `selecting`）：直接忽略，防止反馈阶段误触。
  /// - **选中同一张牌**（`tileId == selectedTileId`）：视为"确认弃牌"，立即调用
  ///   [confirmDiscard] 提交判定。
  /// - **选中不同牌**：更新 [NaniKiruState.selectedTileId] 并将阶段切换为
  ///   [NaniKiruPhase.selecting]，UI 高亮新选中的牌并等待二次确认。
  ///
  /// ## 设计意图
  ///
  /// 两段式设计（点选 → 再点确认）减少了误触导致的错误提交，同时保留了
  /// 快速双点的流畅体验。
  void onTileTapped(String tileId) {
    if (state.phase != NaniKiruPhase.ready && state.phase != NaniKiruPhase.selecting) return;

    if (state.selectedTileId == tileId) {
      confirmDiscard(tileId);
    } else {
      state = state.copyWith(
        selectedTileId: tileId,
        phase: NaniKiruPhase.selecting,
      );
    }
  }

  /// 确认弃牌，进入反馈阶段。
  ///
  /// [tileId] 玩家弃出的牌的 ID。
  /// [isSkip]  是否由"跳过"操作触发（可选，默认 `false`）。
  ///            跳过时 `isPerfect` 强制为 `false`，不计入正确统计。
  ///
  /// ## 判定逻辑
  ///
  /// - 正常提交：`isPerfect = (tileId == correctDiscardId)`。
  /// - 跳过操作：`isPerfect = false`（无论 tileId 是否匹配正确答案）。
  ///
  /// ## 状态变更
  ///
  /// 将阶段设为 [NaniKiruPhase.feedback]，UI 层根据 [NaniKiruState.isPerfect]
  /// 展示正确 ✓ 或错误 ✗ 的视觉反馈。
  void confirmDiscard(String tileId, {bool isSkip = false}) {
    final isPerfect = isSkip ? false : tileId == state.correctDiscardId;
    state = state.copyWith(
      phase: NaniKiruPhase.feedback,
      isPerfect: isPerfect,
    );
  }

  /// 对手牌按"花色 → 数值"规则排序。
  ///
  /// ## 排序规则
  ///
  /// 1. 一级排序：按 [TileModel.suit] 的枚举索引升序（万→饼→索→字），
  ///    同花色牌聚在一起。
  /// 2. 二级排序（同花色内）：
  ///    - 若 [TileModel.value] 为 `int`（数牌 1~9），按数值升序排列。
  ///    - 若 value 非 `int`（字牌使用字符串表示），回退按 [TileModel.id] 字符串排序。
  ///
  /// ## 调用时机
  ///
  /// 通常在摸牌后（手牌增加至 14 张）由 UI 的排序按钮触发，帮助玩家
  /// 按习惯布局观察手牌。谜题已结束时（[state.isFinished]）忽略此次排序。
  void sortHand() {
    if (state.isFinished) return;
    final sorted = List<TileModel>.from(state.handTiles)
      ..sort((a, b) {
        final suitOrder = a.suit.index.compareTo(b.suit.index);
        if (suitOrder != 0) return suitOrder;
        return a.value is int && b.value is int
            ? (a.value as int).compareTo(b.value as int)
            : a.id.compareTo(b.id);
      });
    state = state.copyWith(handTiles: sorted);
  }

  /// 进入下一道谜题。
  ///
  /// 直接委托给 [initPuzzle]，触发完整的谜题生成流程：
  /// 重新计算难度、生成新谜题、重置倒计时和阶段。
  ///
  /// 通常在反馈阶段由"下一题"按钮触发。
  void nextPuzzle() {
    initPuzzle();
  }
}
