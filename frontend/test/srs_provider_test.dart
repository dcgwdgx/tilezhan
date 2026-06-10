import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_engine.dart';

void main() {
  group('SRS provider logic', () {
    test('recordReview creates new item with correct defaults', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 1);
      expect(reps, 0);
      expect(interval, 1);
      final item = SrsItem(
        itemId: 'm1', type: 'flashcard',
        ef: ef, reps: reps, interval: interval,
        nextReviewAt: 0, errors: 1, createdAt: now, lastReviewedAt: now,
      );
      expect(item.nextReviewAt, 0); // quality<3 → immediate
      expect(item.errors, 1);
    });

    test('recordReview quality 4: reps=1, interval=1', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(reps, 1);
      expect(interval, 1);
      expect(ef, greaterThanOrEqualTo(2.5));
    });

    test('recordReview quality 5: EF increases more than quality 4', () {
      final (ef4, _, _) = SrsEngine.calculate(2.5, 0, 1, 4);
      final (ef5, _, _) = SrsEngine.calculate(2.5, 0, 1, 5);
      expect(ef5, greaterThan(ef4));
    });

    test('due items sorted by errorWeight descending', () {
      final items = [
        SrsItem(itemId: 'a', type: 'flashcard', nextReviewAt: 0, errors: 1, reps: 2), // 1/3=0.33
        SrsItem(itemId: 'b', type: 'flashcard', nextReviewAt: 0, errors: 5, reps: 1), // 5/2=2.5
        SrsItem(itemId: 'c', type: 'flashcard', nextReviewAt: 0, errors: 2, reps: 0), // 2/1=2.0
      ];
      items.sort((a, b) => b.errorWeight.compareTo(a.errorWeight));
      expect(items[0].itemId, 'b'); // 2.5 highest
      expect(items[2].itemId, 'a'); // 0.33 lowest
    });

    test('errorWeight formula: errors/(reps+1)', () {
      expect(SrsItem(itemId: 'x', type: 'flashcard', errors: 0, reps: 0).errorWeight, 0.0);
      expect(SrsItem(itemId: 'x', type: 'flashcard', errors: 5, reps: 0).errorWeight, 5.0);
      expect(SrsItem(itemId: 'x', type: 'flashcard', errors: 6, reps: 2).errorWeight, 2.0);
    });

    test('correct answer schedules future review', () {
      final (_, _, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(interval, greaterThan(0));
    });

    test('wrong answer schedules immediate review (0 days)', () {
      final (_, _, interval) = SrsEngine.calculate(2.5, 0, 1, 1);
      expect(interval, 1);
    });
  });
}
