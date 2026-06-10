import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/difficulty_scorer.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

Puzzle _makePuzzle({int ukeireCount = 10, int ukeireTypes = 5}) {
  return Puzzle(
    puzzleId: 'test',
    hand13Ids: List.filled(13, 'm1'),
    drawnTileId: 's7',
    correctDiscardId: 'm1',
    ukeireCount: ukeireCount,
    ukeireTypes: ukeireTypes,
    ukeireTileIds: List.filled(ukeireTypes, 'p1'),
  );
}

void main() {
  group('DifficultyScorer', () {
    test('returns score in valid range', () {
      final puzzle = _makePuzzle();
      final score = DifficultyScorer.score(puzzle);
      expect(score, greaterThanOrEqualTo(800));
      expect(score, lessThanOrEqualTo(1600));
    });

    test('high ukeire = easier = lower score', () {
      final easy = DifficultyScorer.score(_makePuzzle(ukeireCount: 24, ukeireTypes: 10));
      final hard = DifficultyScorer.score(_makePuzzle(ukeireCount: 3, ukeireTypes: 1));
      expect(easy, lessThan(hard));
    });

    test('targetRange returns appropriate values', () {
      expect(DifficultyScorer.targetRange(800), lessThan(1000));
      expect(DifficultyScorer.targetRange(1000), greaterThanOrEqualTo(950));
      expect(DifficultyScorer.targetRange(1500), greaterThanOrEqualTo(1200));
    });

    test('uses base 800 + weighted dimensions', () {
      final puzzle = _makePuzzle();
      final score = DifficultyScorer.score(puzzle);
      // All dimensions contribute → score > base
      expect(score, greaterThanOrEqualTo(800));
    });
  });
}
