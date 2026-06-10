import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/data/tile_repository.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/storage/storage_service.dart';
import 'nanikiru_state.dart';
import 'puzzle_generator.dart';
import 'difficulty_scorer.dart';

final nanikiruProvider =
    StateNotifierProvider.autoDispose<NanikiruNotifier, NaniKiruState>(
        (ref) => NanikiruNotifier(ref.read(tileRepositoryProvider), ref));

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
