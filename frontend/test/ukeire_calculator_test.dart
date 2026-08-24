import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';

void main() {
  group('UkeireCalculator', () {
    test('requires exactly fourteen physically valid tiles', () {
      expect(() => UkeireCalculator(['m1']), throwsArgumentError);
      expect(
        () => UkeireCalculator([
          'm1',
          'm1',
          'm1',
          'm1',
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
        ]),
        throwsArgumentError,
      );
      expect(
        () => UkeireCalculator([
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
          'z8',
        ]),
        throwsArgumentError,
      );
    });

    test('returns one entry per unique discard tile', () {
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

      final results = UkeireCalculator(hand).calculate();

      expect(results.keys.toSet(), hand.toSet());
      expect(results.length, hand.toSet().length);
    });

    test('calculates an exact two-sided wait after the optimal discard', () {
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

      final result = UkeireCalculator(hand).calculate()['z2']!;

      expect(result.shantenAfter, 0);
      expect(result.ukeireTypes.toSet(), {'p4', 'p7'});
      expect(result.ukeireCount, 7);
    });

    test('calculates exact closed, edge, pair, and single waits', () {
      final cases = <({List<String> hand13, Set<String> waits, int count})>[
        (
          hand13: [
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
          ],
          waits: {'p3'},
          count: 4,
        ),
        (
          hand13: [
            'm1',
            'm2',
            'm3',
            'm4',
            'm5',
            'm6',
            's1',
            's2',
            's3',
            'p1',
            'p2',
            'z1',
            'z1',
          ],
          waits: {'p3'},
          count: 4,
        ),
        (
          hand13: [
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
          ],
          waits: {'p5', 's7'},
          count: 4,
        ),
        (
          hand13: [
            'm1',
            'm2',
            'm3',
            'm4',
            'm5',
            'm6',
            'p1',
            'p2',
            'p3',
            's7',
            's8',
            's9',
            'z1',
          ],
          waits: {'z1'},
          count: 3,
        ),
      ];

      for (final waitCase in cases) {
        final result = UkeireCalculator([
          ...waitCase.hand13,
          'z2',
        ]).calculate()['z2']!;
        expect(result.shantenAfter, 0);
        expect(result.ukeireTypes.toSet(), waitCase.waits);
        expect(result.ukeireCount, waitCase.count);
      }
    });

    test('counts a discarded effective tile as already visible', () {
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
        's3',
        'z1',
        'z1',
      ];

      final result = UkeireCalculator(hand).calculate()['z1']!;

      expect(result.shantenAfter, 0);
      expect(result.ukeireTypes, ['z1']);
      expect(result.ukeireCount, 2);
    });

    test('never offers a fifth copy as an effective tile', () {
      final hand = [
        'm1',
        'm1',
        'm1',
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p1',
        'p2',
        'p3',
        'z1',
        'z1',
      ];

      final results = UkeireCalculator(hand).calculate();

      for (final result in results.values) {
        expect(result.ukeireTypes, isNot(contains('m1')));
        expect(result.ukeireCount, inInclusiveRange(0, 122));
      }
    });
  });
}
