import 'dart:math';

import '../../../shared/engine/ukeire_calculator.dart';
import '../../../shared/models/puzzle_model.dart';
import 'nanikiru_teaching_analysis.dart';

/// Selects a nearby Nanikiru puzzle while occasionally targeting weak skills.
///
/// Selection remains local and deterministic when [random] and
/// [explorationRoll] are supplied. Derived teaching tags are cached in memory
/// by puzzle ID and are never written back to the puzzle catalog.
class AdaptiveNanikiruPuzzleSelector {
  AdaptiveNanikiruPuzzleSelector({Random? random})
      : _random = random ?? Random();

  static const _candidateWindowSize = 8;
  static const _explorationRate = 0.2;
  static final Map<String, Set<NanikiruTeachingTag>> _tagCache = {};

  final Random _random;

  /// Returns one puzzle, or `null` when [puzzles] is empty.
  ///
  /// Candidates are ordered by distance from [targetDifficulty], then by ID,
  /// before the nearest eight form the exploration window. When the catalog
  /// has a puzzle matching [preferredTags], 80% of selections use the matching
  /// pool and 20% explore the original difficulty-matched window.
  ///
  /// If every puzzle is excluded, exclusions are relaxed so a session can
  /// continue instead of failing. Invalid analysis data is treated as having
  /// no matching tags and therefore follows the normal fallback path.
  Puzzle? select({
    required List<Puzzle> puzzles,
    required int targetDifficulty,
    Set<String> excludedPuzzleIds = const {},
    Set<NanikiruTeachingTag> preferredTags = const {},
    double? explorationRoll,
  }) {
    if (explorationRoll != null &&
        (explorationRoll.isNaN ||
            explorationRoll < 0 ||
            explorationRoll >= 1)) {
      throw RangeError.value(
        explorationRoll,
        'explorationRoll',
        'Must be at least 0 and less than 1',
      );
    }
    if (puzzles.isEmpty) return null;

    var candidates = puzzles
        .where((puzzle) => !excludedPuzzleIds.contains(puzzle.puzzleId))
        .toList();
    if (candidates.isEmpty) candidates = List<Puzzle>.from(puzzles);

    candidates.sort((left, right) {
      final leftDistance = (left.difficulty - targetDifficulty).abs();
      final rightDistance = (right.difficulty - targetDifficulty).abs();
      final byDistance = leftDistance.compareTo(rightDistance);
      return byDistance != 0
          ? byDistance
          : left.puzzleId.compareTo(right.puzzleId);
    });

    final window =
        candidates.take(_candidateWindowSize).toList(growable: false);
    if (preferredTags.isEmpty) return _pick(window);

    // Exploitation searches the verified catalog, not just the nearest
    // difficulty window. An explicit focused lesson can therefore guarantee
    // its requested skill whenever the catalog contains a matching puzzle.
    var preferred = candidates
        .where((puzzle) => _tagsFor(puzzle).any(preferredTags.contains))
        .toList(growable: false);
    if (preferred.isEmpty && excludedPuzzleIds.isNotEmpty) {
      preferred = puzzles
          .where((puzzle) => _tagsFor(puzzle).any(preferredTags.contains))
          .toList(growable: true)
        ..sort((left, right) {
          final leftDistance = (left.difficulty - targetDifficulty).abs();
          final rightDistance = (right.difficulty - targetDifficulty).abs();
          final byDistance = leftDistance.compareTo(rightDistance);
          return byDistance != 0
              ? byDistance
              : left.puzzleId.compareTo(right.puzzleId);
        });
    }
    if (preferred.isEmpty) return _pick(window);

    final roll = explorationRoll ?? _random.nextDouble();
    return _pick(roll < _explorationRate ? window : preferred);
  }

  Puzzle _pick(List<Puzzle> puzzles) =>
      puzzles[_random.nextInt(puzzles.length)];

  Set<NanikiruTeachingTag> _tagsFor(Puzzle puzzle) {
    if (puzzle.puzzleId.isEmpty) return _analyzeTags(puzzle);
    return _tagCache.putIfAbsent(
      puzzle.puzzleId,
      () => _analyzeTags(puzzle),
    );
  }

  Set<NanikiruTeachingTag> _analyzeTags(Puzzle puzzle) {
    try {
      final hand14 = [...puzzle.hand13Ids, puzzle.drawnTileId];
      final results = UkeireCalculator(hand14).calculate();
      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: null,
        results: results,
      );
      return Set<NanikiruTeachingTag>.unmodifiable(analysis.optimalTags);
    } on ArgumentError {
      return const <NanikiruTeachingTag>{};
    } on FormatException {
      return const <NanikiruTeachingTag>{};
    }
  }
}
