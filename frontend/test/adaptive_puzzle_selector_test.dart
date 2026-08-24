import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/adaptive_puzzle_selector.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_teaching_analysis.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

class _FixedRandom implements Random {
  const _FixedRandom({this.doubleValue = 0.9, this.index = 0});

  final double doubleValue;
  final int index;

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => doubleValue;

  @override
  int nextInt(int max) => index % max;
}

void main() {
  group('AdaptiveNanikiruPuzzleSelector', () {
    test('targets a preferred skill during the exploitation path', () {
      final generic = _genericPuzzle('hit_generic', 1000);
      final kokushi = _kokushiPuzzle('hit_kokushi', 1004);
      final selector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(index: 0),
      );

      final selected = selector.select(
        puzzles: [generic, kokushi],
        targetDifficulty: 1000,
        preferredTags: const {NanikiruTeachingTag.kokushiTendency},
        explorationRoll: 0.9,
      );

      expect(selected?.puzzleId, 'hit_kokushi');
    });

    test('finds a focused skill beyond the nearest difficulty window', () {
      final nearby = [
        for (var index = 0; index < 8; index++)
          _genericPuzzle('near_$index', 1000 + index),
      ];
      final farKokushi = _kokushiPuzzle('far_kokushi', 1400);
      final selector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(index: 0),
      );

      final selected = selector.select(
        puzzles: [...nearby, farKokushi],
        targetDifficulty: 1000,
        preferredTags: const {NanikiruTeachingTag.kokushiTendency},
        explorationRoll: 0.9,
      );

      expect(selected?.puzzleId, 'far_kokushi');
    });

    test('uses the original nearby window on the exploration path', () {
      final kokushi = _kokushiPuzzle('explore_kokushi', 1000);
      final generic = _genericPuzzle('explore_generic', 1001);
      final selector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(doubleValue: 0.1, index: 1),
      );

      final selected = selector.select(
        puzzles: [kokushi, generic],
        targetDifficulty: 1000,
        preferredTags: const {NanikiruTeachingTag.kokushiTendency},
      );

      expect(selected?.puzzleId, 'explore_generic');
    });

    test('falls back by distance and ID without a matching weakness', () {
      final selector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(index: 0),
      );
      final laterById = _genericPuzzle('fallback_z', 900);
      final firstById = _genericPuzzle('fallback_a', 1100);

      final selected = selector.select(
        puzzles: [laterById, firstById],
        targetDifficulty: 1000,
        preferredTags: const {NanikiruTeachingTag.kokushiTendency},
      );

      expect(selected?.puzzleId, 'fallback_a');
      expect(
        selector.select(puzzles: const [], targetDifficulty: 1000),
        isNull,
      );
    });

    test('honors exclusions and relaxes them only when all are excluded', () {
      final first = _kokushiPuzzle('excluded_first', 1000);
      final second = _kokushiPuzzle('excluded_second', 1001);
      final selector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(index: 0),
      );

      final selected = selector.select(
        puzzles: [first, second],
        targetDifficulty: 1000,
        excludedPuzzleIds: {'excluded_first'},
        preferredTags: const {NanikiruTeachingTag.kokushiTendency},
        explorationRoll: 0.9,
      );
      expect(selected?.puzzleId, 'excluded_second');

      final allExcluded = selector.select(
        puzzles: [first, second],
        targetDifficulty: 1000,
        excludedPuzzleIds: {'excluded_first', 'excluded_second'},
      );
      expect(allExcluded, isNotNull);
      expect(
        {'excluded_first', 'excluded_second'},
        contains(allExcluded!.puzzleId),
      );
    });

    test('reuses a focused match before falling back to another skill', () {
      final focused = _kokushiPuzzle('only_focused_match', 1200);
      final generic = _genericPuzzle('nearby_generic', 1000);
      final selector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(index: 0),
      );

      final selected = selector.select(
        puzzles: [focused, generic],
        targetDifficulty: 1000,
        excludedPuzzleIds: {'only_focused_match'},
        preferredTags: const {NanikiruTeachingTag.kokushiTendency},
        explorationRoll: 0.9,
      );

      expect(selected?.puzzleId, 'only_focused_match');
    });

    test('reuses the process-wide puzzle ID tag cache', () {
      final initial = _kokushiPuzzle('cache_shared', 1000);
      final firstSelector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(),
      );
      expect(
        firstSelector
            .select(
              puzzles: [initial],
              targetDifficulty: 1000,
              preferredTags: const {
                NanikiruTeachingTag.kokushiTendency,
              },
              explorationRoll: 0.9,
            )
            ?.puzzleId,
        'cache_shared',
      );

      final replacement = _invalidPuzzleWithId('cache_shared', 1000);
      final fallback = _genericPuzzle('cache_fallback', 1001);
      final secondSelector = AdaptiveNanikiruPuzzleSelector(
        random: const _FixedRandom(index: 1),
      );
      final selected = secondSelector.select(
        puzzles: [replacement, fallback],
        targetDifficulty: 1000,
        preferredTags: const {NanikiruTeachingTag.kokushiTendency},
        explorationRoll: 0.9,
      );

      expect(identical(selected, replacement), isTrue);
    });
  });
}

Puzzle _genericPuzzle(String id, int difficulty) => Puzzle(
      puzzleId: id,
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
      difficulty: difficulty,
    );

Puzzle _kokushiPuzzle(String id, int difficulty) => Puzzle(
      puzzleId: id,
      hand13Ids: const [
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
      ],
      drawnTileId: 'z7',
      correctDiscardId: 'm1',
      ukeireCount: 39,
      ukeireTypes: 13,
      ukeireTileIds: const [
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
      ],
      difficulty: difficulty,
    );

Puzzle _invalidPuzzleWithId(String id, int difficulty) => Puzzle(
      puzzleId: id,
      hand13Ids: const ['m1'],
      drawnTileId: 'm2',
      correctDiscardId: 'm1',
      ukeireCount: 0,
      ukeireTypes: 0,
      ukeireTileIds: const [],
      difficulty: difficulty,
    );
