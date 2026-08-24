/// Tests for the enhanced Nanikiru review panel.
///
/// Covers:
/// - NaniKiruState allDiscardUkeire and allDiscardUkeireTiles fields
/// - UkeireCalculator DiscardResult public API
/// - Data-driven explanation text (via state fields)
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_state.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';

void main() {
  group('DiscardResult', () {
    test('is publicly constructable', () {
      const result = DiscardResult(
        shantenAfter: 2,
        ukeireTypes: ['m1', 'm4', 'm7'],
        ukeireCount: 11,
      );
      expect(result.shantenAfter, 2);
      expect(result.ukeireTypes, ['m1', 'm4', 'm7']);
      expect(result.ukeireCount, 11);
    });

    test('all fields are accessible externally', () {
      const result = DiscardResult(
        shantenAfter: 0,
        ukeireTypes: ['p3', 'p6'],
        ukeireCount: 7,
      );
      expect(result.shantenAfter, isA<int>());
      expect(result.ukeireTypes, isA<List<String>>());
      expect(result.ukeireCount, isA<int>());
    });
  });

  group('UkeireCalculator', () {
    test('produces DiscardResult for each unique tile in hand', () {
      // A simple 14-tile hand with two pairs
      const hand = ['m1', 'm1', 'm2', 'm3', 'm3', 'm4', 'm5', 'm5', 'm6', 'm7', 'm8', 'm8', 'm9', 's7'];
      final results = UkeireCalculator(hand).calculate();

      // Each unique tile in the hand should have an entry
      final uniqueTiles = hand.toSet();
      for (final tile in uniqueTiles) {
        expect(results.containsKey(tile), isTrue, reason: 'Missing entry for $tile');
      }

      // Every result should have valid data
      for (final entry in results.values) {
        expect(entry.ukeireCount, greaterThanOrEqualTo(0));
        expect(entry.shantenAfter, greaterThanOrEqualTo(-1));
      }
    });

    test('results can be stored in NaniKiruState maps', () {
      const hand = ['m1', 'm1', 'm2', 'm3', 'm3', 'm4', 'm5', 'm5', 'm6', 'm7', 'm8', 'm8', 'm9', 's7'];
      final results = UkeireCalculator(hand).calculate();

      final allDiscardUkeire = <String, int>{};
      final allDiscardUkeireTiles = <String, List<String>>{};
      for (final entry in results.entries) {
        allDiscardUkeire[entry.key] = entry.value.ukeireCount;
        allDiscardUkeireTiles[entry.key] = entry.value.ukeireTypes;
      }

      // Verify the maps can be stored in state
      final state = NaniKiruState(
        allDiscardUkeire: allDiscardUkeire,
        allDiscardUkeireTiles: allDiscardUkeireTiles,
      );
      expect(state.allDiscardUkeire, isNotNull);
      expect(state.allDiscardUkeireTiles, isNotNull);
      expect(state.allDiscardUkeire!.length, results.length);
    });
  });

  group('NaniKiruState review fields', () {
    test('allDiscardUkeire defaults to null', () {
      const state = NaniKiruState();
      expect(state.allDiscardUkeire, isNull);
      expect(state.allDiscardUkeireTiles, isNull);
    });

    test('allDiscardUkeire is preserved through copyWith', () {
      const ukeire = {'m1': 5, 'm2': 8};
      const tiles = {
        'm1': ['m3', 'm4'],
        'm2': ['m5', 'm6', 'm7'],
      };

      final state = const NaniKiruState(
        allDiscardUkeire: ukeire,
        allDiscardUkeireTiles: tiles,
      );

      // copyWith without ukeire params preserves them
      final copied = state.copyWith(countdownValue: 5.0);
      expect(copied.allDiscardUkeire, ukeire);
      expect(copied.allDiscardUkeireTiles, tiles);
      expect(copied.countdownValue, 5.0);
    });

    test('allDiscardUkeire can be updated via copyWith', () {
      const oldUkeire = {'m1': 5};
      const newUkeire = {'m1': 10, 'p3': 15};

      final state = const NaniKiruState(allDiscardUkeire: oldUkeire);
      final updated = state.copyWith(allDiscardUkeire: newUkeire);
      expect(updated.allDiscardUkeire, newUkeire);
      expect(updated.allDiscardUkeireTiles, isNull); // not touched
    });

    test('full state constructor accepts all fields', () {
      const ukeire = {'m1': 12, 'p5': 8};
      const ukeireTiles = {'m1': ['m2', 'm4', 'm7'], 'p5': ['p3', 'p6']};

      const state = NaniKiruState(
        handTiles: [],
        drawnTileId: 'm1',
        correctDiscardId: 'p5',
        selectedTileId: 'm1',
        phase: NaniKiruPhase.feedback,
        countdownValue: 3.5,
        isPerfect: true,
        ukeireCount: 12,
        ukeireTypes: 3,
        ukeireTiles: ['m2', 'm4', 'm7'],
        puzzleId: 'test_001',
        allDiscardUkeire: ukeire,
        allDiscardUkeireTiles: ukeireTiles,
      );

      expect(state.allDiscardUkeire, ukeire);
      expect(state.allDiscardUkeireTiles, ukeireTiles);
      expect(state.isPerfect, true);
      expect(state.isFinished, true);
    });
  });
}
