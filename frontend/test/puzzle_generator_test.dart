import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/puzzle_generator.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

void main() {
  group('PuzzleGenerator', () {
    test('fallback is a fully verified single-answer puzzle', () {
      final puzzle = PuzzleGenerator.generate(maxAttempts: 0);

      expect(puzzle.hand13Ids, [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p5',
        'p6',
        'p7',
        'p8',
        'p9',
        'z1',
        'z1',
      ]);
      expect(puzzle.drawnTileId, 'z2');
      expect(puzzle.correctDiscardId, 'z2');
      expect(puzzle.ukeireTileIds.toSet(), {'p4', 'p7'});
      expect(puzzle.ukeireTypes, 2);
      expect(puzzle.ukeireCount, 7);

      _expectUniqueOptimalAnswer(puzzle);
    });

    test('generated puzzle is legal and its answer is uniquely optimal', () {
      final puzzle = PuzzleGenerator.generate(random: Random(20260824));
      final all14 = [...puzzle.hand13Ids, puzzle.drawnTileId];

      expect(puzzle.hand13Ids, hasLength(13));
      expect(all14, hasLength(14));
      expect(all14, everyElement(isIn(_validTileIds)));
      expect(all14, contains(puzzle.correctDiscardId));
      expect(puzzle.ukeireCount, greaterThanOrEqualTo(2));
      expect(puzzle.ukeireTypes, puzzle.ukeireTileIds.length);
      expect(puzzle.difficulty, inInclusiveRange(800, 1600));

      final counts = <String, int>{};
      for (final tileId in all14) {
        counts[tileId] = (counts[tileId] ?? 0) + 1;
      }
      expect(counts.values, everyElement(lessThanOrEqualTo(4)));
      _expectUniqueOptimalAnswer(puzzle);
    });

    test('a fixed random seed produces repeatable puzzle content', () {
      final first = PuzzleGenerator.generate(random: Random(4242));
      final second = PuzzleGenerator.generate(random: Random(4242));

      expect(second.hand13Ids, first.hand13Ids);
      expect(second.drawnTileId, first.drawnTileId);
      expect(second.correctDiscardId, first.correctDiscardId);
      expect(second.ukeireTileIds, first.ukeireTileIds);
      expect(second.ukeireCount, first.ukeireCount);
      expect(second.difficulty, first.difficulty);
    });

    test('rejects a negative attempt count', () {
      expect(
        () => PuzzleGenerator.generate(maxAttempts: -1),
        throwsArgumentError,
      );
    });
  });
}

void _expectUniqueOptimalAnswer(Puzzle puzzle) {
  final results = UkeireCalculator([
    ...puzzle.hand13Ids,
    puzzle.drawnTileId,
  ]).calculate();
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

  expect(winners, hasLength(1));
  expect(winners.single.key, puzzle.correctDiscardId);
  expect(winners.single.value.ukeireTypes, puzzle.ukeireTileIds);
  expect(winners.single.value.ukeireCount, puzzle.ukeireCount);
}

const _validTileIds = {
  'm1',
  'm2',
  'm3',
  'm4',
  'm5',
  'm6',
  'm7',
  'm8',
  'm9',
  'p1',
  'p2',
  'p3',
  'p4',
  'p5',
  'p6',
  'p7',
  'p8',
  'p9',
  's1',
  's2',
  's3',
  's4',
  's5',
  's6',
  's7',
  's8',
  's9',
  'z1',
  'z2',
  'z3',
  'z4',
  'z5',
  'z6',
  'z7',
};
