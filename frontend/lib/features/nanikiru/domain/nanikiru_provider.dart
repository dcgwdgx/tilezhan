import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/data/tile_repository.dart';
import '../../../core/providers/tile_data_provider.dart';
import 'nanikiru_state.dart';
import 'puzzle_generator.dart';

final nanikiruProvider =
    StateNotifierProvider.autoDispose<NanikiruNotifier, NaniKiruState>(
        (ref) => NanikiruNotifier(ref.read(tileRepositoryProvider)));

class NanikiruNotifier extends StateNotifier<NaniKiruState> {
  final TileRepository _repo;
  List<TileModel> _allTiles = [];
  int _puzzleCounter = 0;

  NanikiruNotifier(this._repo) : super(const NaniKiruState());

  Future<void> initPuzzle() async {
    _allTiles = await _repo.loadAllTiles();

    // Generate random puzzle
    final puzzle = PuzzleGenerator.generate();
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
      confirmDiscard(state.correctDiscardId);
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

  void confirmDiscard(String tileId) {
    final isPerfect = tileId == state.correctDiscardId;
    state = state.copyWith(
      phase: NaniKiruPhase.feedback,
      isPerfect: isPerfect,
    );
  }

  void nextPuzzle() {
    initPuzzle();
  }
}
