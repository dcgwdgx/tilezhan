import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/hand_analyzer/domain/hand_analyzer.dart';

void main() {
  group('HandAnalyzer 13-tile draw analysis', () {
    test('returns exact winning draws and theoretical remaining copies', () {
      final analysis = HandAnalyzer.analyze([
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        's1',
        's2',
        's3',
        'p5',
        'p5',
        's7',
        's7',
      ]) as DrawHandAnalysis;

      expect(analysis.minimumShanten, 0);
      expect(analysis.shantenBreakdown.standard, 0);
      expect(analysis.effectiveTileIds, ['p5', 's7']);
      expect(analysis.effectiveTileTypeCount, 2);
      expect(analysis.totalEffectiveTileCount, 4);
      expect(
        analysis.effectiveDraws.map((draw) => (
              draw.tileId,
              draw.minimumShantenAfterDraw,
              draw.theoreticalRemainingCopies,
            )),
        [('p5', -1, 2), ('s7', -1, 2)],
      );
    });

    test('closed wait is counted without inventing visible outside tiles', () {
      final analysis = HandAnalyzer.analyze([
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        's1',
        's2',
        's3',
        'p2',
        'p4',
        'z1',
        'z1',
      ]) as DrawHandAnalysis;

      expect(analysis.minimumShanten, 0);
      expect(analysis.effectiveTileIds, ['p3']);
      expect(analysis.effectiveDraws.single.minimumShantenAfterDraw, -1);
      expect(analysis.effectiveDraws.single.theoreticalRemainingCopies, 4);
      expect(analysis.totalEffectiveTileCount, 4);
    });
  });

  group('HandAnalyzer 14-tile discard analysis', () {
    test('ranks every unique discard with the exact ukeire engine', () {
      final hand = [
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

      final analysis = HandAnalyzer.analyze(hand) as DiscardHandAnalysis;

      expect(analysis.minimumShanten, 0);
      expect(analysis.candidates, hasLength(hand.toSet().length));
      expect(analysis.byDiscard.keys.toSet(), hand.toSet());

      final best = analysis.candidates.first;
      expect(best.tileId, 'z2');
      expect(best.rank, 1);
      expect(best.isOptimal, isTrue);
      expect(best.minimumShantenAfterDiscard, 0);
      expect(best.effectiveTileIds, ['p4', 'p7']);
      expect(best.effectiveTileTypeCount, 2);
      expect(best.effectiveTileCount, 7);
      expect(analysis.bestCandidates, contains(best));

      for (var index = 1; index < analysis.candidates.length; index++) {
        expect(
          _compareCandidates(
            analysis.candidates[index - 1],
            analysis.candidates[index],
          ),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('preserves competition ranks for real engine ties', () {
      final analysis = HandAnalyzer.analyze([
        'm1',
        'm2',
        'm3',
        'p1',
        'p2',
        'p3',
        's1',
        's2',
        's3',
        'z1',
        'z1',
        'z1',
        'z2',
        'z2',
      ]) as DiscardHandAnalysis;

      final m1 = analysis.byDiscard['m1']!;
      final p1 = analysis.byDiscard['p1']!;
      final s1 = analysis.byDiscard['s1']!;
      expect(
        (
          m1.minimumShantenAfterDiscard,
          m1.effectiveTileCount,
          m1.effectiveTileTypeCount,
        ),
        (
          p1.minimumShantenAfterDiscard,
          p1.effectiveTileCount,
          p1.effectiveTileTypeCount,
        ),
      );
      expect(
        (
          p1.minimumShantenAfterDiscard,
          p1.effectiveTileCount,
          p1.effectiveTileTypeCount,
        ),
        (
          s1.minimumShantenAfterDiscard,
          s1.effectiveTileCount,
          s1.effectiveTileTypeCount,
        ),
      );
      expect({m1.rank, p1.rank, s1.rank}, hasLength(1));

      final firstTiedIndex = analysis.candidates.indexOf(m1);
      expect(m1.rank, firstTiedIndex + 1);
      expect(analysis.candidates[firstTiedIndex + 1].rank, m1.rank);
      expect(analysis.candidates[firstTiedIndex + 2].rank, m1.rank);
    });

    test('keeps a complete-hand boundary and still offers all discards', () {
      final analysis = HandAnalyzer.analyze([
        'm1',
        'm2',
        'm3',
        'p1',
        'p2',
        'p3',
        's1',
        's2',
        's3',
        'z1',
        'z1',
        'z1',
        'z2',
        'z2',
      ]) as DiscardHandAnalysis;

      expect(analysis.minimumShanten, -1);
      expect(analysis.shantenBreakdown.standard, -1);
      expect(analysis.candidates, hasLength(11));
      expect(
        analysis.candidates.every(
          (candidate) => candidate.minimumShantenAfterDiscard == 0,
        ),
        isTrue,
      );
    });
  });

  group('HandAnalyzer validation and immutable snapshots', () {
    test('accepts only 13 or 14 tiles', () {
      expect(
        () => HandAnalyzer.analyze(List.filled(12, 'm1')),
        throwsArgumentError,
      );
      expect(
        () => HandAnalyzer.analyze([
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
        ]),
        throwsArgumentError,
      );
    });

    test('rejects malformed IDs and a fifth physical copy', () {
      expect(
        () => HandAnalyzer.analyze([
          'm1',
          'm2',
          'm3',
          'm4',
          'm5',
          'm6',
          'm7',
          'p1',
          'p2',
          'p3',
          's1',
          's2',
          'z1',
          'z8',
        ]),
        throwsArgumentError,
      );
      expect(
        () => HandAnalyzer.analyze([
          'm1',
          'm1',
          'm1',
          'm1',
          'm1',
          'm2',
          'm3',
          'm4',
          'm5',
          'p1',
          'p2',
          'p3',
          'z1',
        ]),
        throwsArgumentError,
      );
    });

    test('copies input and exposes only unmodifiable collections', () {
      final source = [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        's1',
        's2',
        's3',
        'p2',
        'p4',
        'z1',
        'z1',
      ];
      final analysis = HandAnalyzer.analyze(source) as DrawHandAnalysis;

      source[0] = 'z7';
      expect(analysis.handTiles.first, 'm1');
      expect(
        () => analysis.handTiles.add('z7'),
        throwsUnsupportedError,
      );
      expect(
        () => analysis.effectiveDraws.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => analysis.effectiveTileIds.add('z7'),
        throwsUnsupportedError,
      );

      final discardAnalysis = HandAnalyzer.analyze([
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
      ]) as DiscardHandAnalysis;
      expect(
        () => discardAnalysis.candidates.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => discardAnalysis.bestCandidates.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => discardAnalysis.byDiscard.remove('z2'),
        throwsUnsupportedError,
      );
      expect(
        () => discardAnalysis.candidates.first.effectiveTileIds.add('z7'),
        throwsUnsupportedError,
      );
    });
  });
}

int _compareCandidates(DiscardCandidate left, DiscardCandidate right) {
  final byShanten = left.minimumShantenAfterDiscard
      .compareTo(right.minimumShantenAfterDiscard);
  if (byShanten != 0) return byShanten;

  final byCount = right.effectiveTileCount.compareTo(left.effectiveTileCount);
  if (byCount != 0) return byCount;

  return right.effectiveTileTypeCount.compareTo(left.effectiveTileTypeCount);
}
