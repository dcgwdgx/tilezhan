import '../../../shared/models/tile_model.dart';

enum NaniKiruPhase { ready, selecting, animating, feedback }

class NaniKiruState {
  final List<TileModel> handTiles;
  final String drawnTileId;
  final String correctDiscardId;
  final String? selectedTileId;
  final NaniKiruPhase phase;
  final double countdownValue;
  final bool isPerfect;
  final int? ukeireCount;
  final int? ukeireTypes;
  final List<String>? ukeireTiles;
  final String puzzleId; // for SRS tracking

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

  bool get isFinished => phase == NaniKiruPhase.feedback;

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
      selectedTileId: selectedTileId,
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
