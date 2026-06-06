import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/data/tile_repository.dart';
import 'nanikiru_state.dart';

final nanikiruProvider =
    StateNotifierProvider.autoDispose<NanikiruNotifier, NaniKiruState>(
        (ref) => NanikiruNotifier(ref.read(tileRepositoryProvider)));

class NanikiruNotifier extends StateNotifier<NaniKiruState> {
  final TileRepository _repo;
  List<TileModel> _allTiles = [];

  NanikiruNotifier(this._repo) : super(const NaniKiruState());

  // Hardcoded demo hand for MVP: 13 Manzu + 1 drawn Souzu
  static const _demoHandIds = [
    'm1', 'm1', 'm2', 'm3', 'm3', 'm4', 'm5', 'm5',
    'm6', 'm7', 'm8', 'm8', 'm9',
  ];
  static const _demoDrawnId = 's7';
  static const _demoCorrectId = 'm4';

  Future<void> initPuzzle() async {
    _allTiles = await _repo.loadAllTiles();
    final handTiles = _demoHandIds
        .map((id) => _repo.getById(id, _allTiles))
        .whereType<TileModel>()
        .toList();
    final drawnTile = _repo.getById(_demoDrawnId, _allTiles);

    state = NaniKiruState(
      handTiles: [...handTiles, if (drawnTile != null) drawnTile],
      drawnTileId: _demoDrawnId,
      correctDiscardId: _demoCorrectId,
      phase: NaniKiruPhase.ready,
      countdownValue: 10.0,
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
      // Second tap — confirm discard
      confirmDiscard(tileId);
    } else {
      // First tap — select
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
      ukeireCount: isPerfect ? 11 : 4,
      ukeireTypes: isPerfect ? 3 : 1,
      ukeireTiles: isPerfect ? ['2p', '5p', '8p'] : ['4p'],
    );
  }

  void nextPuzzle() {
    initPuzzle();
  }
}
