import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';

void main() {
  group('UkeireCalculator', () {
    test('requires exactly 14 tiles', () {
      expect(() => UkeireCalculator(['m1']), throwsArgumentError);
      expect(() => UkeireCalculator(List.filled(15, 'm1')), throwsArgumentError);
    });

    test('returns results for each unique discard', () {
      final hand = ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9','s7'];
      final results = UkeireCalculator(hand).calculate();
      // Should have results for each unique tile type
      expect(results.length, lessThanOrEqualTo(14));
      expect(results.keys, contains('m1'));
    });

    test('result has shanten, ukeire types and count', () {
      final hand = ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9','s7'];
      final results = UkeireCalculator(hand).calculate();
      final first = results.values.first;
      expect(first.shantenAfter, isNonNegative);
      expect(first.ukeireTypes, isA<List<String>>());
      expect(first.ukeireCount, isNonNegative);
    });

    test('handles hands with duplicates correctly', () {
      // Hand with 4 copies of one tile
      final hand = ['m1','m1','m1','m1','m2','m3','m4','m5','m6','p1','p2','p3','p4','p5'];
      final results = UkeireCalculator(hand).calculate();
      // Should not crash
      expect(results, isNotEmpty);
    });

    test('ukeire count never exceeds max available tiles', () {
      final hand = ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9','s7'];
      final results = UkeireCalculator(hand).calculate();
      for (final r in results.values) {
        expect(r.ukeireCount, lessThanOrEqualTo(34 * 4 - 14)); // max tiles remaining
      }
    });
  });
}
