/// 何切 (Nanikiru) 谜题状态管理模块。
///
/// 提供基于 Riverpod 的 [StateNotifierProvider] 和 [NanikiruNotifier]，
/// 负责谜题的生成、倒计时、选牌交互和判定反馈。
/// 难度随用户 ELO 自适应，由 [DifficultyScorer] 和 [PuzzleGenerator] 协作完成。
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
final nanikiruProvider =
    StateNotifierProvider.autoDispose<NanikiruNotifier, NaniKiruState>(
        (ref) => NanikiruNotifier(ref.read(tileRepositoryProvider), ref));

/// 管理何切谜题的完整生命周期。
///
/// 职责包括：
/// - 加载全量牌库并根据用户 ELO 生成自适应难度的谜题
/// - 处理倒计时 tick、选牌 tap、确认弃牌及手牌排序
/// - 控制谜题状态流转：准备 → 选择中 → 反馈 → 下一题
class NanikiruNotifier extends StateNotifier<NaniKiruState> {
  final TileRepository _repo;
  final Ref _ref;
  List<TileModel> _allTiles = [];
  int _puzzleCounter = 0;

  NanikiruNotifier(this._repo, this._ref) : super(const NaniKiruState());

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

  void tickCountdown(double delta) {
    if (state.isFinished) return;
    final newValue = (state.countdownValue - delta).clamp(0.0, 10.0);
    state = state.copyWith(countdownValue: newValue);
    if (newValue <= 0 && !state.isFinished) {
      confirmDiscard(state.selectedTileId ?? '');
    }
  }

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

  void confirmDiscard(String tileId, {bool isSkip = false}) {
    final isPerfect = isSkip ? false : tileId == state.correctDiscardId;
    state = state.copyWith(
      phase: NaniKiruPhase.feedback,
      isPerfect: isPerfect,
    );
  }

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

  void nextPuzzle() {
    initPuzzle();
  }
}
