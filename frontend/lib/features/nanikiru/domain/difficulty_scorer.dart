/// Objective difficulty rating for Nanikiru puzzles.
///
/// Ratings span 800-1600 and are derived from the complete discard analysis,
/// rather than estimating hand structure from the winning ukeire count alone.

import 'dart:math';

import 'package:tilezhan/shared/engine/ukeire_calculator.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

class DifficultyScorer {
  /// Scores a puzzle using its full per-discard engine analysis.
  ///
  /// Callers that already calculated [discardResults] should pass them to avoid
  /// repeating the work. The six normalized dimensions are:
  ///
  /// - post-discard shanten distance;
  /// - number of visually distinct discard choices;
  /// - breadth of the winning effective-tile set;
  /// - margin over the strongest same-shanten alternative;
  /// - proportion of near-optimal traps;
  /// - proportion of alternatives that preserve the best shanten.
  static int score(
    Puzzle puzzle, {
    Map<String, DiscardResult>? discardResults,
  }) {
    final results = discardResults ??
        UkeireCalculator([
          ...puzzle.hand13Ids,
          puzzle.drawnTileId,
        ]).calculate();
    final correct = results[puzzle.correctDiscardId];
    if (correct == null) {
      throw ArgumentError.value(
        puzzle.correctDiscardId,
        'puzzle.correctDiscardId',
        'The answer is not a discard candidate',
      );
    }

    final bestShanten =
        results.values.map((result) => result.shantenAfter).reduce(min);
    final bestUkeire = results.values
        .where((result) => result.shantenAfter == bestShanten)
        .map((result) => result.ukeireCount)
        .reduce(max);
    if (correct.shantenAfter != bestShanten ||
        correct.ukeireCount != bestUkeire) {
      throw ArgumentError.value(
        puzzle.correctDiscardId,
        'puzzle.correctDiscardId',
        'The supplied answer is not engine-optimal',
      );
    }
    if (puzzle.ukeireCount != correct.ukeireCount ||
        puzzle.ukeireTypes != correct.ukeireTypes.length ||
        !_sameItems(puzzle.ukeireTileIds, correct.ukeireTypes)) {
      throw ArgumentError.value(
        puzzle.puzzleId,
        'puzzle',
        'The supplied ukeire metadata does not match the engine analysis',
      );
    }

    final alternatives = results.entries
        .where((entry) => entry.key != puzzle.correctDiscardId)
        .map((entry) => entry.value)
        .toList();
    final sameShanten = alternatives
        .where((result) => result.shantenAfter == bestShanten)
        .toList();
    final denominator = max(1, alternatives.length);

    final shantenDistance = (bestShanten.clamp(0, 3) / 3).toDouble();
    final choiceComplexity =
        ((results.length - 5) / 9).clamp(0.0, 1.0).toDouble();
    final ukeireComplexity =
        ((correct.ukeireTypes.length - 1) / 9).clamp(0.0, 1.0).toDouble();

    var trapCloseness = 0.0;
    if (sameShanten.isNotEmpty) {
      final runnerUp =
          sameShanten.map((result) => result.ukeireCount).reduce(max);
      final margin = correct.ukeireCount - runnerUp;
      trapCloseness = (1.0 - (margin / 12).clamp(0.0, 1.0)).toDouble();
    }

    final nearOptimalRatio = sameShanten
            .where((result) => correct.ukeireCount - result.ukeireCount <= 4)
            .length /
        denominator;
    final sameShantenRatio = sameShanten.length / denominator;

    final normalized = (shantenDistance * 0.18) +
        (choiceComplexity * 0.14) +
        (ukeireComplexity * 0.14) +
        (trapCloseness * 0.28) +
        (nearOptimalRatio * 0.14) +
        (sameShantenRatio * 0.12);

    return (800 + normalized * 800).round().clamp(800, 1600).toInt();
  }

  /// Maps the player's ELO to the desired puzzle rating band.
  static int targetRange(int userElo) {
    if (userElo < 900) return 850;
    if (userElo < 1100) return 1000;
    if (userElo < 1300) return 1200;
    return 1400;
  }

  static bool _sameItems(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    return left.toSet().containsAll(right) && right.toSet().containsAll(left);
  }
}
