import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_engine.dart';

void main() {
  group('SrsEngine — SM-2 algorithm', () {
    // ── New item, perfect recall ──
    test('first perfect recall (q=5): interval=1, reps=1, ef>2.5', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 5);
      expect(reps, 1);
      expect(interval, 1);
      expect(ef, greaterThan(2.5));
    });

    test('first perfect recall (q=4): interval=1, reps=1', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(reps, 1);
      expect(interval, 1);
    });

    test('first hesitant recall (q=3): interval=1, reps=1, EF may decrease', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 3);
      expect(reps, 1);
      expect(interval, 1);
      expect(ef, greaterThanOrEqualTo(1.3)); // EF floor applies
    });

    // ── Failed recall — resets ──
    test('failed recall (q=2): reps reset to 0, interval reset to 1', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 3, 6, 2);
      expect(reps, 0);
      expect(interval, 1);
    });

    test('complete blackout (q=0): reps=0, interval=1, EF unchanged', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 5, 10, 0);
      expect(reps, 0);
      expect(interval, 1);
      expect(ef, 2.5); // EF preserved on fail
    });

    test('borderline fail (q=2): EF preserved, reps=0', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.8, 4, 8, 2);
      expect(reps, 0);
      expect(interval, 1);
      expect(ef, 2.8); // EF unchanged
    });

    // ── Progression ──
    test('second perfect recall (reps 1→2): interval=6', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.6, 1, 1, 5);
      expect(reps, 2);
      expect(interval, 6);
    });

    test('third perfect recall: interval = prev_interval × ef', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.6, 2, 6, 5);
      expect(reps, 3);
      expect(interval, (6 * ef).round());
    });

    // ── EF floor ──
    test('EF never drops below 1.3', () {
      // Simulate repeated poor-but-passing reviews
      var ef = 2.5;
      var reps = 0;
      var interval = 1;
      for (int i = 0; i < 20; i++) {
        final (newEf, newReps, newInterval) = SrsEngine.calculate(ef, reps, interval, 3);
        ef = newEf;
        reps = newReps;
        interval = newInterval;
      }
      expect(ef, greaterThanOrEqualTo(1.3));
    });

    // ── Quality mapping from app context ──
    test('quality 5 (correct + mnemonic) → interval advances', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 5);
      expect(reps, 1);
      expect(interval, 1);
    });

    test('quality 4 (correct) → interval advances', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(reps, 1);
      expect(interval, 1);
    });

    test('quality 1 (wrong) → reset', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 5, 20, 1);
      expect(reps, 0);
      expect(interval, 1);
    });

    test('quality 0 (timeout) → reset', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 5, 20, 0);
      expect(reps, 0);
      expect(interval, 1);
    });

    // ── Determinism ──
    test('same inputs produce same outputs', () {
      final a = SrsEngine.calculate(2.5, 3, 10, 4);
      final b = SrsEngine.calculate(2.5, 3, 10, 4);
      expect(a.$1, b.$1);
      expect(a.$2, b.$2);
      expect(a.$3, b.$3);
    });
  });
}
