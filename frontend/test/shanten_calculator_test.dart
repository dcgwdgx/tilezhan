import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/engine/shanten_calculator.dart';

void main() {
  group('standard hand shanten', () {
    test('complete hand is -1', () {
      final hand = [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p2',
        'p3',
        'p4',
        'p5',
        'p6',
        'p7',
        's1',
        's1',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), -1);
    });

    test('two-sided wait is tenpai', () {
      final hand = [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p2',
        'p3',
        'p4',
        'p5',
        'p6',
        's1',
        's1',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    test('ordinary incomplete hand is exactly one-shanten', () {
      final hand = [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p2',
        'p3',
        'p5',
        'p6',
        's1',
        's1',
        'z1',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 1);
    });

    test('single wait is tenpai', () {
      final hand = [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p2',
        'p3',
        'p4',
        's1',
        's2',
        's3',
        'z1',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    test('nine gates base shape is tenpai', () {
      final hand = [
        'm1',
        'm1',
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'm7',
        'm8',
        'm9',
        'm9',
        'm9',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    test('four copies can split across a triplet and a sequence', () {
      final hand = [
        'm1',
        'm1',
        'm1',
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
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), -1);
    });

    test('extra taatsu beyond four do not lower shanten further', () {
      final hand = [
        'm1',
        'm2',
        'm4',
        'm5',
        'm7',
        'm8',
        'p1',
        'p2',
        'p4',
        'p5',
        's1',
        's2',
        'z1',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 4);
    });

    test('fourteen-tile incomplete shape is not treated as complete', () {
      final hand = [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p1',
        'p2',
        'p3',
        's1',
        's2',
        'z1',
        'z1',
        'z2',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });
  });

  group('special hand shanten', () {
    test('seven distinct pairs are complete', () {
      final hand = [
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
        's1',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), -1);
    });

    test('six distinct pairs and one singleton are tenpai', () {
      final hand = [
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
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    test('standard and seven-pairs interpretations can compete', () {
      final hand = [
        'm1',
        'm1',
        'm2',
        'm2',
        'm3',
        'm3',
        'm4',
        'm4',
        'm5',
        'm5',
        'm6',
        'm6',
        'm7',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    test('seven pairs accounts for too few unique tile kinds', () {
      final hand = [
        'm1',
        'm1',
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
        's1',
        's1',
      ];

      expect(ShantenCalculator.fromIds(hand).calculate(), 1);
    });

    test('complete thirteen orphans is -1', () {
      final hand = [
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

      expect(ShantenCalculator.fromIds(hand).calculate(), -1);
    });

    test('thirteen unique orphans are tenpai', () {
      final hand = [
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

      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });
  });

  group('exact shanten breakdown gold cases', () {
    test('standard shape reports all three exact values', () {
      final calculator = ShantenCalculator.fromIds([
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p2',
        'p3',
        'p4',
        'p5',
        'p6',
        'p7',
        's1',
        's1',
      ]);

      final result = calculator.calculateBreakdown();

      expect(result.standard, -1);
      expect(result.sevenPairs, 5);
      expect(result.thirteenOrphans, 10);
      expect(result.minimum, -1);
      expect(calculator.calculate(), result.minimum);
    });

    test('seven-pairs shape reports all three exact values', () {
      final calculator = ShantenCalculator.fromIds([
        'm1',
        'm1',
        'm4',
        'm4',
        'm7',
        'm7',
        'p2',
        'p2',
        'p5',
        'p5',
        's3',
        's3',
        'z1',
        'z1',
      ]);

      final result = calculator.calculateBreakdown();

      expect(result.standard, 3);
      expect(result.sevenPairs, -1);
      expect(result.thirteenOrphans, 10);
      expect(result.minimum, -1);
      expect(calculator.calculate(), result.minimum);
    });

    test('thirteen-orphans shape reports all three exact values', () {
      final calculator = ShantenCalculator.fromIds([
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
      ]);

      final result = calculator.calculateBreakdown();

      expect(result.standard, 7);
      expect(result.sevenPairs, 5);
      expect(result.thirteenOrphans, -1);
      expect(result.minimum, -1);
      expect(calculator.calculate(), result.minimum);
    });
  });

  group('input validation and state safety', () {
    test('rejects malformed or out-of-range tile IDs', () {
      for (final id in ['1m', 'm0', 'm10', 'z8', 'x1', '']) {
        expect(() => ShantenCalculator.fromIds([id]), throwsArgumentError);
      }
    });

    test('rejects a fifth copy and more than fourteen tiles', () {
      expect(
        () => ShantenCalculator.fromIds(List.filled(5, 'm1')),
        throwsArgumentError,
      );
      expect(
        () => ShantenCalculator.fromIds([
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

    test('direct constructor validates length and copies its input', () {
      expect(() => ShantenCalculator(List.filled(33, 0)), throwsArgumentError);

      final counts = List<int>.filled(34, 0);
      counts[0] = 1;
      final calculator = ShantenCalculator(counts);
      counts[0] = 4;

      expect(calculator.calculate(), 8);
      expect(calculator.calculate(), 8);
    });
  });
}
