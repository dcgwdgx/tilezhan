import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_provider.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_snapshot.dart';

class _MemorySrsNotifier extends SrsReviewNotifier {
  @override
  Map<String, SrsItem> build() => {};
}

void main() {
  const hand13 = [
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
  ];

  group('Nanikiru SRS snapshot', () {
    test('new snapshots declare rules engine version 2', () {
      final content = buildNanikiruSnapshotContent(
        puzzleId: 'puzzle-1',
        hand13Ids: hand13,
        drawnTileId: 'z2',
        correctDiscardId: 'z2',
        ukeireCount: 7,
        ukeireTypes: 2,
        ukeireTileIds: const ['p4', 'p7'],
        difficulty: 900,
        metadata: const {
          'engineVersion': 999,
          'lastOutcome': 'incorrect',
        },
      );

      expect(content['engineVersion'], nanikiruEngineVersion);
      expect(content['lastOutcome'], 'incorrect');
    });

    test(
        'old wrong snapshot is recomputed and normalized when answer is unique',
        () {
      final resolved = resolveNanikiruSnapshotContent(
        {
          'puzzleId': 'legacy-unique',
          'hand13Ids': hand13,
          'drawnTileId': 'z2',
          'correctDiscardId': 'm1',
          'ukeireCount': 99,
          'ukeireTypes': 99,
          'ukeireTileIds': ['z7'],
          'difficulty': 999,
          'lastOutcome': 'incorrect',
        },
        fallbackPuzzleId: 'fallback-id',
      );

      expect(resolved, isNotNull);
      expect(resolved!.needsMigration, isTrue);
      expect(resolved.puzzle.puzzleId, 'legacy-unique');
      expect(resolved.puzzle.correctDiscardId, 'z2');
      expect(resolved.puzzle.ukeireCount, 7);
      expect(resolved.puzzle.ukeireTypes, 2);
      expect(resolved.puzzle.ukeireTileIds, ['p4', 'p7']);
      expect(resolved.puzzle.difficulty, inInclusiveRange(800, 1600));
      expect(resolved.content['engineVersion'], nanikiruEngineVersion);
      expect(resolved.content['correctDiscardId'], 'z2');
      expect(resolved.content['lastOutcome'], 'incorrect');
    });

    test('old snapshot with tied optimal discards is skipped safely', () {
      final resolved = resolveNanikiruSnapshotContent(
        const {
          'hand13Ids': [
            'm1',
            'm2',
            'm3',
            'm4',
            'm5',
            'm6',
            'p1',
            'p2',
            'p3',
            'p4',
            'p5',
            'p6',
            'z1',
          ],
          'drawnTileId': 'z1',
          'correctDiscardId': 'm1',
          'ukeireCount': 0,
          'ukeireTypes': 0,
          'ukeireTileIds': <String>[],
          'difficulty': 1000,
        },
        fallbackPuzzleId: 'legacy-ambiguous',
      );

      expect(resolved, isNull);
    });

    test('content migration preserves every SM-2 scheduling field', () {
      final container = ProviderContainer(
        overrides: [
          srsNotifierProvider.overrideWith(_MemorySrsNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(srsNotifierProvider.notifier);
      const original = SrsItem(
        itemId: 'legacy-unique',
        type: 'nanikiru',
        ef: 1.7,
        reps: 4,
        interval: 17,
        nextReviewAt: 123456,
        errors: 3,
        createdAt: 111,
        lastReviewedAt: 222,
        content: {'engineVersion': 1},
      );

      notifier.replaceContentPreservingSchedule(
        original,
        const {'engineVersion': nanikiruEngineVersion},
      );

      final migrated = container.read(srsNotifierProvider)['legacy-unique']!;
      expect(migrated.ef, original.ef);
      expect(migrated.reps, original.reps);
      expect(migrated.interval, original.interval);
      expect(migrated.nextReviewAt, original.nextReviewAt);
      expect(migrated.errors, original.errors);
      expect(migrated.createdAt, original.createdAt);
      expect(migrated.lastReviewedAt, original.lastReviewedAt);
      expect(migrated.content, {'engineVersion': nanikiruEngineVersion});
    });
  });
}
