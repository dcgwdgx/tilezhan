import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/difficulty_scorer.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

void main() {
  group('DifficultyScorer', () {
    test('uses the full decision landscape and spans commercial ELO bands', () {
      final easyAnalysis = <String, DiscardResult>{
        'z2': _result(0, ['p3'], 4),
        'm1': _result(1, ['m1', 'm4'], 7),
        'm2': _result(1, ['m2'], 4),
        'm3': _result(2, ['m3'], 4),
        'm4': _result(2, ['m4'], 4),
      };
      final hardAnalysis = <String, DiscardResult>{
        'z2': _result(3, _tenWaits, 20),
        for (var index = 0; index < 13; index++)
          'candidate_$index': _result(3, ['m1'], 19 - index),
      };

      final easy = DifficultyScorer.score(
        _puzzle(ukeireTiles: ['p3'], ukeireCount: 4),
        discardResults: easyAnalysis,
      );
      final hard = DifficultyScorer.score(
        _puzzle(ukeireTiles: _tenWaits, ukeireCount: 20),
        discardResults: hardAnalysis,
      );

      expect(easy, inInclusiveRange(800, 1050));
      expect(hard, inInclusiveRange(1400, 1600));
      expect(hard, greaterThan(easy));
    });

    test('can calculate a real verified puzzle without injected analysis', () {
      final score = DifficultyScorer.score(
        Puzzle(
          puzzleId: 'fallback',
          hand13Ids: const [
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
          ],
          drawnTileId: 'z2',
          correctDiscardId: 'z2',
          ukeireCount: 7,
          ukeireTypes: 2,
          ukeireTileIds: const ['p4', 'p7'],
        ),
      );

      expect(score, inInclusiveRange(800, 1600));
    });

    test('rejects a non-optimal answer or stale ukeire metadata', () {
      final analysis = <String, DiscardResult>{
        'z2': _result(0, ['p3'], 4),
        'm1': _result(0, ['m2', 'm5'], 8),
      };

      expect(
        () => DifficultyScorer.score(
          _puzzle(ukeireTiles: ['p3'], ukeireCount: 4),
          discardResults: analysis,
        ),
        throwsArgumentError,
      );

      final staleMetadata = <String, DiscardResult>{
        'z2': _result(0, ['p3'], 4),
        'm1': _result(1, ['m2'], 4),
      };
      expect(
        () => DifficultyScorer.score(
          _puzzle(ukeireTiles: ['p3'], ukeireCount: 3),
          discardResults: staleMetadata,
        ),
        throwsArgumentError,
      );
    });

    test('maps player ELO to all four intended bands', () {
      expect(DifficultyScorer.targetRange(800), 850);
      expect(DifficultyScorer.targetRange(1000), 1000);
      expect(DifficultyScorer.targetRange(1200), 1200);
      expect(DifficultyScorer.targetRange(1500), 1400);
    });
  });
}

DiscardResult _result(int shanten, List<String> types, int count) =>
    DiscardResult(
      shantenAfter: shanten,
      ukeireTypes: types,
      ukeireCount: count,
    );

Puzzle _puzzle({required List<String> ukeireTiles, required int ukeireCount}) =>
    Puzzle(
      puzzleId: 'test',
      hand13Ids: const [
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
      ],
      drawnTileId: 'z2',
      correctDiscardId: 'z2',
      ukeireCount: ukeireCount,
      ukeireTypes: ukeireTiles.length,
      ukeireTileIds: ukeireTiles,
    );

const _tenWaits = [
  'm1',
  'm2',
  'm3',
  'm4',
  'm5',
  'p1',
  'p2',
  'p3',
  's1',
  's2',
];
