import 'dart:math';

import '../../../shared/engine/ukeire_calculator.dart';
import '../../../shared/models/puzzle_model.dart';
import 'difficulty_scorer.dart';

/// Version of the rules engine used to produce Nanikiru SRS snapshots.
///
/// Version 1 and unversioned snapshots predate the exact shanten/ukeire engine.
const int nanikiruEngineVersion = 2;

/// A playable snapshot together with the normalized content to persist.
class NanikiruSnapshotResolution {
  const NanikiruSnapshotResolution({
    required this.puzzle,
    required this.content,
    required this.needsMigration,
  });

  final Puzzle puzzle;
  final Map<String, dynamic> content;
  final bool needsMigration;
}

/// Builds the canonical content payload stored inside a Nanikiru SRS item.
Map<String, dynamic> buildNanikiruSnapshotContent({
  required String puzzleId,
  required List<String> hand13Ids,
  required String drawnTileId,
  required String correctDiscardId,
  required int ukeireCount,
  required int ukeireTypes,
  required List<String> ukeireTileIds,
  required int difficulty,
  Map<String, dynamic> metadata = const {},
}) {
  return {
    ...metadata,
    'engineVersion': nanikiruEngineVersion,
    'puzzleId': puzzleId,
    'hand13Ids': List<String>.from(hand13Ids),
    'drawnTileId': drawnTileId,
    'correctDiscardId': correctDiscardId,
    'ukeireCount': ukeireCount,
    'ukeireTypes': ukeireTypes,
    'ukeireTileIds': List<String>.from(ukeireTileIds),
    'difficulty': difficulty,
  };
}

/// Loads a current snapshot or migrates an older one with the exact engine.
///
/// Old and unversioned snapshots are accepted only when the current engine
/// finds exactly one discard with both the minimum shanten and the maximum
/// ukeire among those minimum-shanten choices. Ambiguous snapshots return
/// `null` so callers can skip them instead of teaching a false distinction.
NanikiruSnapshotResolution? resolveNanikiruSnapshotContent(
  Map<String, dynamic> content, {
  required String fallbackPuzzleId,
}) {
  try {
    final hand13Ids = _stringList(content['hand13Ids']);
    final drawnTileId = content['drawnTileId'];
    if (hand13Ids == null ||
        hand13Ids.length != 13 ||
        drawnTileId is! String ||
        drawnTileId.isEmpty) {
      return null;
    }

    final rawVersion = content['engineVersion'];
    final version = rawVersion is num ? rawVersion.toInt() : null;
    if (version != null && version > nanikiruEngineVersion) {
      // A newer app may have written semantics this build does not understand.
      return null;
    }

    if (version == nanikiruEngineVersion) {
      final puzzle = _parseCurrentSnapshot(
        content,
        fallbackPuzzleId: fallbackPuzzleId,
        hand13Ids: hand13Ids,
        drawnTileId: drawnTileId,
      );
      if (puzzle == null) return null;
      return NanikiruSnapshotResolution(
        puzzle: puzzle,
        content: Map<String, dynamic>.from(content),
        needsMigration: false,
      );
    }

    final results = UkeireCalculator([...hand13Ids, drawnTileId]).calculate();
    if (results.isEmpty) return null;

    final bestShanten =
        results.values.map((result) => result.shantenAfter).reduce(min);
    final bestUkeire = results.values
        .where((result) => result.shantenAfter == bestShanten)
        .map((result) => result.ukeireCount)
        .reduce(max);
    final winners = results.entries
        .where((entry) =>
            entry.value.shantenAfter == bestShanten &&
            entry.value.ukeireCount == bestUkeire)
        .toList();
    if (winners.length != 1) return null;

    final winner = winners.single;
    final puzzleId = _nonEmptyString(content['puzzleId']) ?? fallbackPuzzleId;
    final unscored = Puzzle(
      puzzleId: puzzleId,
      hand13Ids: hand13Ids,
      drawnTileId: drawnTileId,
      correctDiscardId: winner.key,
      ukeireCount: winner.value.ukeireCount,
      ukeireTypes: winner.value.ukeireTypes.length,
      ukeireTileIds: List<String>.from(winner.value.ukeireTypes),
      difficulty: 0,
    );
    final difficulty = DifficultyScorer.score(
      unscored,
      discardResults: results,
    );
    final migratedContent = buildNanikiruSnapshotContent(
      metadata: content,
      puzzleId: puzzleId,
      hand13Ids: hand13Ids,
      drawnTileId: drawnTileId,
      correctDiscardId: winner.key,
      ukeireCount: winner.value.ukeireCount,
      ukeireTypes: winner.value.ukeireTypes.length,
      ukeireTileIds: winner.value.ukeireTypes,
      difficulty: difficulty,
    );

    return NanikiruSnapshotResolution(
      puzzle: Puzzle(
        puzzleId: puzzleId,
        hand13Ids: hand13Ids,
        drawnTileId: drawnTileId,
        correctDiscardId: winner.key,
        ukeireCount: winner.value.ukeireCount,
        ukeireTypes: winner.value.ukeireTypes.length,
        ukeireTileIds: List<String>.from(winner.value.ukeireTypes),
        difficulty: difficulty,
      ),
      content: migratedContent,
      needsMigration: true,
    );
  } catch (_) {
    return null;
  }
}

Puzzle? _parseCurrentSnapshot(
  Map<String, dynamic> content, {
  required String fallbackPuzzleId,
  required List<String> hand13Ids,
  required String drawnTileId,
}) {
  final correctDiscardId = _nonEmptyString(content['correctDiscardId']);
  final ukeireTileIds = _stringList(content['ukeireTileIds']);
  final ukeireCount = content['ukeireCount'];
  final ukeireTypes = content['ukeireTypes'];
  final difficulty = content['difficulty'];
  if (correctDiscardId == null ||
      ![...hand13Ids, drawnTileId].contains(correctDiscardId) ||
      ukeireTileIds == null ||
      ukeireCount is! num ||
      ukeireTypes is! num ||
      difficulty is! num) {
    return null;
  }

  return Puzzle(
    puzzleId: _nonEmptyString(content['puzzleId']) ?? fallbackPuzzleId,
    hand13Ids: hand13Ids,
    drawnTileId: drawnTileId,
    correctDiscardId: correctDiscardId,
    ukeireCount: ukeireCount.toInt(),
    ukeireTypes: ukeireTypes.toInt(),
    ukeireTileIds: ukeireTileIds,
    difficulty: difficulty.toInt(),
  );
}

List<String>? _stringList(Object? value) {
  if (value is! List || value.any((item) => item is! String)) return null;
  return List<String>.from(value);
}

String? _nonEmptyString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}
