/// 何切 (What to Discard) puzzle immutable state model.
///
/// Defines the core domain types for a single nanikiru puzzle round:
/// the phase-driven lifecycle ([NaniKiruPhase]) and the hand-crafted
/// immutable [NaniKiruState] that carries all puzzle data through
/// selection, animation, and feedback stages.
import '../../../shared/models/tile_model.dart';

/// The lifecycle phases of a single nanikiru puzzle round.
///
/// * [ready] — puzzle loaded, awaiting user tap on a tile.
/// * [selecting] — user has tapped; confirm selection via animation.
/// * [animating] — discard animation in progress.
/// * [feedback] — show result (correct/incorrect, uke-ire breakdown).
enum NaniKiruPhase { ready, selecting, animating, feedback }

/// Immutable state for a single nanikiru puzzle round.
///
/// Holds the hand, the drawn tile, the correct answer, user selection,
/// lifecycle [phase], countdown progress, and (after feedback) the
/// uke-ire analysis.  Designed to be updated exclusively via [copyWith].
class NaniKiruState {
  /// The 13 tiles currently in the player's hand (before the draw).
  final List<TileModel> handTiles;

  /// The tile just drawn; the player must discard one tile from the
  /// resulting 14-tile hand.
  final String drawnTileId;

  /// The tile-id that is the correct discard for this puzzle.
  final String correctDiscardId;

  /// The tile-id the user has selected, if any.
  final String? selectedTileId;

  /// Current lifecycle phase of the puzzle round.
  final NaniKiruPhase phase;

  /// Remaining countdown seconds for timed rounds.
  final double countdownValue;

  /// Whether the user's final selection matched [correctDiscardId].
  final bool isPerfect;

  /// Total number of winning draws (uke-ire count) after the correct
  /// discard.  Populated during the feedback phase.
  final int? ukeireCount;

  /// Number of distinct tile *types* that contribute to uke-ire.
  final int? ukeireTypes;

  /// The specific tile-ids that would complete the hand (wait).
  final List<String>? ukeireTiles;

  /// Persistent puzzle identifier used for SRS (spaced-repetition)
  /// scheduling and statistics tracking.
  final String puzzleId;

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

  /// Whether the puzzle round has concluded and the feedback overlay
  /// should be shown.
  bool get isFinished => phase == NaniKiruPhase.feedback;

  /// Returns a new [NaniKiruState] with the given fields replaced.
  ///
  /// Every parameter is optional; omitted parameters keep their current
  /// value.  This is the only way to produce a new state — [NaniKiruState]
  /// itself has no mutable setters.
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
