/// Puzzle model for Nani-Kiru questions.
class Puzzle {
  final String puzzleId;
  final List<String> hand13Ids;
  final String drawnTileId;
  final String correctDiscardId;
  final int ukeireCount;
  final int ukeireTypes;
  final List<String> ukeireTileIds;
  final int difficulty; // Puzzle Rating (800-1300)

  const Puzzle({
    required this.puzzleId,
    required this.hand13Ids,
    required this.drawnTileId,
    required this.correctDiscardId,
    required this.ukeireCount,
    required this.ukeireTypes,
    required this.ukeireTileIds,
    this.difficulty = 1000,
  });
}
