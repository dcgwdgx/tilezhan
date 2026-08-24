import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_teaching_analysis.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';

void main() {
  group('NanikiruTeachingAnalyzer ranking', () {
    test('uses engine shanten then ukeire and preserves competition ranks', () {
      final hand14 = [
        ...List.filled(4, 'm1'),
        ...List.filled(4, 'm2'),
        ...List.filled(3, 'm3'),
        ...List.filled(3, 'm4'),
      ];
      final results = {
        'm1': _result(shanten: 1, count: 40, tiles: ['p1']),
        'm2': _result(shanten: 0, count: 8, tiles: ['p2', 'p3']),
        'm3': _result(shanten: 0, count: 12, tiles: ['p4', 'p5']),
        'm4': _result(shanten: 0, count: 12, tiles: ['p6', 'p7']),
      };

      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: 'm1',
        results: results,
      );

      expect(
        analysis.topCandidates.map((candidate) => candidate.discardId),
        ['m3', 'm4', 'm2'],
      );
      expect(
        analysis.topCandidates.map((candidate) => candidate.rank),
        [1, 1, 3],
      );
      expect(analysis.topCandidates[2].shantenDifferenceFromBest, 0);
      expect(analysis.topCandidates[2].ukeireLossFromBest, 4);
      expect(analysis.selectedCandidate!.rank, 4);
      expect(analysis.selectedCandidate!.shantenDifferenceFromBest, 1);
      expect(analysis.selectedCandidate!.ukeireLossFromBest, isNull);
      expect(analysis.selectedCandidate!.isOptimal, isFalse);
      expect(
        analysis.bestCandidate.tags,
        contains(NanikiruTeachingTag.taatsuOverload),
      );
    });

    test('integrates with exact UkeireCalculator results', () {
      final hand14 = [
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
        'z2',
      ];
      final results = UkeireCalculator(hand14).calculate();

      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: 'p8',
        results: results,
      );

      expect(analysis.bestCandidate.discardId, 'z2');
      expect(analysis.bestCandidate.rank, 1);
      expect(analysis.bestCandidate.shantenAfter, 0);
      expect(analysis.bestCandidate.ukeireTileIds, ['p4', 'p7']);
      expect(analysis.bestCandidate.ukeireTypes, 2);
      expect(analysis.bestCandidate.ukeireCount, 7);
      expect(analysis.bestCandidate.shantenDifferenceFromBest, 0);
      expect(analysis.bestCandidate.ukeireLossFromBest, 0);
      expect(analysis.bestCandidate.isOptimal, isTrue);
      expect(
        analysis.bestCandidate.tags,
        containsAll({
          NanikiruTeachingTag.isolatedTileHandling,
          NanikiruTeachingTag.pairProtection,
        }),
      );
      expect(analysis.selectedCandidate!.discardId, 'p8');
      expect(analysis.selectedCandidate!.shantenAfter,
          results['p8']!.shantenAfter);
      expect(
          analysis.selectedCandidate!.ukeireCount, results['p8']!.ukeireCount);
      expect(analysis.evaluatedCandidateCount, hand14.toSet().length);
      expect(analysis.byDiscard.keys.toSet(), hand14.toSet());
    });
  });

  group('NanikiruTeachingAnalyzer semantic tags', () {
    test('marks a live chiitoitsu route without changing engine ranking', () {
      final hand14 = [
        'm1',
        'm1',
        'm2',
        'm2',
        'm3',
        'm3',
        'p1',
        'p1',
        'p2',
        'p2',
        'p3',
        'p3',
        's1',
        's2',
      ];
      final results = {
        for (final tileId in hand14.toSet())
          tileId: _result(shanten: 0, count: 4, tiles: ['z1']),
      };

      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: 'm1',
        results: results,
      );

      expect(
        analysis.selectedCandidate!.tags,
        contains(NanikiruTeachingTag.chiitoitsuCompetition),
      );
      expect(analysis.selectedCandidate!.rank, 1);
    });

    test('marks a kokushi-oriented hand', () {
      final hand14 = [
        'm1',
        'm1',
        'm9',
        'p1',
        'p9',
        's1',
        's9',
        'z1',
        'z2',
        'z3',
        'z4',
        'z5',
        'z6',
        'z7',
      ];
      final results = {
        for (final tileId in hand14.toSet())
          tileId: _result(shanten: 0, count: 4, tiles: ['m1']),
      };

      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: 'm1',
        results: results,
      );

      expect(
        analysis.selectedCandidate!.tags,
        contains(NanikiruTeachingTag.kokushiTendency),
      );
    });

    test('falls back to the generic efficiency tag', () {
      final hand14 = [
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
      ];
      final results = {
        for (final tileId in hand14)
          tileId: _result(shanten: 1, count: 8, tiles: ['s1']),
      };

      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: 'm1',
        results: results,
      );

      expect(analysis.selectedCandidate!.tags, {
        NanikiruTeachingTag.generalTileEfficiency,
      });
    });
  });

  group('NanikiruTeachingAnalyzer validation and snapshots', () {
    test('rejects incomplete results and a discard outside the hand', () {
      final hand14 = List.generate(14, (index) => 'm${(index % 9) + 1}');

      expect(
        () => NanikiruTeachingAnalyzer.analyze(
          hand14: hand14,
          selectedDiscardId: 'm1',
          results: {'m1': _result(shanten: 1, count: 4)},
        ),
        throwsArgumentError,
      );
      expect(
        () => NanikiruTeachingAnalyzer.analyze(
          hand14: hand14,
          selectedDiscardId: 'z1',
          results: {
            for (final tileId in hand14.toSet())
              tileId: _result(shanten: 1, count: 4),
          },
        ),
        throwsArgumentError,
      );
    });

    test('returns immutable result snapshots', () {
      final hand14 = [
        ...List.filled(4, 'm1'),
        ...List.filled(4, 'm2'),
        ...List.filled(3, 'm3'),
        ...List.filled(3, 'm4'),
      ];
      final sourceTiles = ['p1'];
      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: 'm1',
        results: {
          for (final tileId in hand14.toSet())
            tileId: _result(shanten: 1, count: 4, tiles: sourceTiles),
        },
      );

      sourceTiles.add('p2');
      expect(analysis.bestCandidate.ukeireTileIds, ['p1']);
      expect(
        () => analysis.topCandidates.add(analysis.bestCandidate),
        throwsUnsupportedError,
      );
      expect(
        () => analysis.bestCandidate.tags.add(
          NanikiruTeachingTag.generalTileEfficiency,
        ),
        throwsUnsupportedError,
      );
      expect(
        () => analysis.byDiscard.remove('m1'),
        throwsUnsupportedError,
      );
    });

    test('supports skip and timeout states without a selected discard', () {
      final hand14 = [
        ...List.filled(4, 'm1'),
        ...List.filled(4, 'm2'),
        ...List.filled(3, 'm3'),
        ...List.filled(3, 'm4'),
      ];
      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: null,
        results: {
          for (final tileId in hand14.toSet())
            tileId: _result(shanten: 1, count: 4),
        },
      );

      expect(analysis.selectedCandidate, isNull);
      expect(analysis.topCandidates, hasLength(3));
      expect(analysis.byDiscard.keys.toSet(), hand14.toSet());
    });

    test('attaches a later choice without rebuilding the candidate catalog',
        () {
      final hand14 = [
        ...List.filled(4, 'm1'),
        ...List.filled(4, 'm2'),
        ...List.filled(3, 'm3'),
        ...List.filled(3, 'm4'),
      ];
      final analysis = NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: null,
        results: {
          'm1': _result(shanten: 1, count: 4),
          'm2': _result(shanten: 0, count: 8),
          'm3': _result(shanten: 0, count: 12),
          'm4': _result(shanten: 0, count: 10),
        },
      );

      final selected = analysis.withSelectedDiscard('m1');

      expect(analysis.selectedCandidate, isNull);
      expect(selected.selectedCandidate?.discardId, 'm1');
      expect(identical(selected.byDiscard, analysis.byDiscard), isTrue);
      expect(() => analysis.withSelectedDiscard('z1'), throwsArgumentError);
      expect(selected.optimalTags, isNotEmpty);
    });
  });
}

DiscardResult _result({
  required int shanten,
  required int count,
  List<String> tiles = const [],
}) =>
    DiscardResult(
      shantenAfter: shanten,
      ukeireTypes: tiles,
      ukeireCount: count,
    );
