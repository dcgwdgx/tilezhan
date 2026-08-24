import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/difficulty_scorer.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_teaching_analysis.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

void main() {
  test('all static Nanikiru puzzles have one exact engine-verified answer', () {
    final raw = jsonDecode(
      File('assets/data/nanikiru_puzzles.json').readAsStringSync(),
    ) as List<dynamic>;

    expect(raw, hasLength(80));
    var easyCount = 0;
    var mediumCount = 0;
    var hardCount = 0;
    final representedTags = <NanikiruTeachingTag>{};
    for (var index = 0; index < raw.length; index++) {
      final puzzle = Map<String, dynamic>.from(raw[index] as Map);
      final difficulty = puzzle['difficulty'] as int;
      if (difficulty <= 1099) {
        easyCount++;
      } else if (difficulty <= 1299) {
        mediumCount++;
      } else {
        hardCount++;
      }
      final hand14 = [
        ...List<String>.from(puzzle['hand13Ids'] as List),
        puzzle['drawnTileId'] as String,
      ];
      final results = UkeireCalculator(hand14).calculate();
      representedTags.addAll(
        NanikiruTeachingAnalyzer.analyze(
          hand14: hand14,
          selectedDiscardId: null,
          results: results,
        ).optimalTags,
      );
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

      expect(winners, hasLength(1), reason: 'Puzzle #$index is ambiguous');
      final winner = winners.single;
      expect(
        puzzle['correctDiscardId'],
        winner.key,
        reason: 'Puzzle #$index has the wrong discard',
      );
      expect(
        List<String>.from(puzzle['ukeireTileIds'] as List),
        winner.value.ukeireTypes,
        reason: 'Puzzle #$index has the wrong effective tiles',
      );
      expect(
        puzzle['ukeireTypes'],
        winner.value.ukeireTypes.length,
        reason: 'Puzzle #$index has the wrong effective-tile type count',
      );
      expect(
        puzzle['ukeireCount'],
        winner.value.ukeireCount,
        reason: 'Puzzle #$index has the wrong effective-tile count',
      );
      final verifiedPuzzle = Puzzle(
        puzzleId: 'static_$index',
        hand13Ids: hand14.take(13).toList(),
        drawnTileId: hand14.last,
        correctDiscardId: winner.key,
        ukeireCount: winner.value.ukeireCount,
        ukeireTypes: winner.value.ukeireTypes.length,
        ukeireTileIds: winner.value.ukeireTypes,
        difficulty: puzzle['difficulty'] as int,
      );
      expect(
        puzzle['difficulty'],
        DifficultyScorer.score(
          verifiedPuzzle,
          discardResults: results,
        ),
        reason: 'Puzzle #$index has a stale difficulty rating',
      );
    }

    expect(easyCount, greaterThanOrEqualTo(16));
    expect(mediumCount, greaterThanOrEqualTo(20));
    expect(hardCount, greaterThanOrEqualTo(16));
    expect(representedTags, containsAll(NanikiruTeachingTag.values));
  });
}
