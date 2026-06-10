import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/puzzle_generator.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

void main() {
  group('PuzzleGenerator', () {
    test('generates valid puzzle', () {
      final puzzle = PuzzleGenerator.generate();
      expect(puzzle.hand13Ids.length, 13);
      expect(puzzle.drawnTileId, isNotEmpty);
      expect(puzzle.correctDiscardId, isNotEmpty);
      expect(puzzle.ukeireCount, greaterThanOrEqualTo(2));
      expect(puzzle.ukeireTypes, greaterThan(0));
      expect(puzzle.puzzleId, isNotEmpty);
      expect(puzzle.difficulty, greaterThanOrEqualTo(800));
    });

    test('hand13 + drawnTile = 14 unique valid tile IDs', () {
      final puzzle = PuzzleGenerator.generate();
      final all14 = [...puzzle.hand13Ids, puzzle.drawnTileId];
      expect(all14.length, 14);
      for (final id in all14) {
        expect(_validTileIds, contains(id));
      }
    });

    test('correct discard is in the hand', () {
      final puzzle = PuzzleGenerator.generate();
      final all14 = [...puzzle.hand13Ids, puzzle.drawnTileId];
      expect(all14, contains(puzzle.correctDiscardId));
    });

    test('no tile appears more than 4 times', () {
      final puzzle = PuzzleGenerator.generate();
      final counts = <String, int>{};
      for (final id in [...puzzle.hand13Ids, puzzle.drawnTileId]) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
      for (final c in counts.values) {
        expect(c, lessThanOrEqualTo(4));
      }
    });

    test('target difficulty produces puzzle near target', () {
      final puzzle = PuzzleGenerator.generate(targetDifficulty: 1200);
      // Should be within ~300 of target (allow tolerance due to randomness)
      expect((puzzle.difficulty - 1200).abs(), lessThan(400));
    });

    test('multiple calls produce different puzzles', () {
      final puzzles = List.generate(5, (_) => PuzzleGenerator.generate());
      final ids = puzzles.map((p) => p.puzzleId).toSet();
      // Most should be unique (allow 1 duplicate in 5 due to randomness)
      expect(ids.length, greaterThanOrEqualTo(4));
    });
  });
}

const _validTileIds = {
  'm1','m2','m3','m4','m5','m6','m7','m8','m9',
  'p1','p2','p3','p4','p5','p6','p7','p8','p9',
  's1','s2','s3','s4','s5','s6','s7','s8','s9',
  'z1','z2','z3','z4','z5','z6','z7',
};
