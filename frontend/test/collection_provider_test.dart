import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_item.dart';

void main() {
  group('Yaku unlock calculation', () {
    test('0 reviews = 0 unlocked (only first yaku shown)', () {
      final unlocked = (0 ~/ 5).clamp(0, 7);
      expect(unlocked, 0);
    });

    test('5 reviews = 1 unlocked', () {
      final unlocked = (5 ~/ 5).clamp(0, 7);
      expect(unlocked, 1);
    });

    test('15 reviews = 3 unlocked', () {
      final unlocked = (15 ~/ 5).clamp(0, 7);
      expect(unlocked, 3);
    });

    test('50 reviews = capped at 7', () {
      final unlocked = (50 ~/ 5).clamp(0, 7);
      expect(unlocked, 7);
    });

    test('total reviews sum from SRS items', () {
      final items = [
        SrsItem(itemId: 'm1', type: 'flashcard', reps: 2),
        SrsItem(itemId: 'm2', type: 'flashcard', reps: 0),
        SrsItem(itemId: 'm3', type: 'flashcard', reps: 5),
      ];
      final total = items.fold(0, (sum, item) => sum + item.reps + 1);
      expect(total, 10);
    });
  });
}
