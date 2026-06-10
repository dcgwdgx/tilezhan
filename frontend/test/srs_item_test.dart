import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_item.dart';

void main() {
  group('SrsItem', () {
    test('default values', () {
      const item = SrsItem(itemId: 'm5', type: 'flashcard');
      expect(item.ef, 2.5);
      expect(item.reps, 0);
      expect(item.interval, 1);
      expect(item.errors, 0);
      expect(item.createdAt, 0);
      expect(item.lastReviewedAt, 0);
    });

    test('errorWeight: errors / (reps + 1)', () {
      final item = SrsItem(itemId: 'm5', type: 'flashcard', errors: 6, reps: 2);
      expect(item.errorWeight, 2.0); // 6/(2+1)
    });

    test('errorWeight: reps=0 returns errors directly', () {
      final item = SrsItem(itemId: 'm5', type: 'flashcard', errors: 5, reps: 0);
      expect(item.errorWeight, 5.0);
    });

    test('toJson → fromJson roundtrip', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = SrsItem(
        itemId: 'm5', type: 'flashcard',
        ef: 2.8, reps: 3, interval: 10,
        nextReviewAt: now + 86400000, errors: 2,
        createdAt: now - 86400000, lastReviewedAt: now,
      );
      final json = item.toJson();
      final restored = SrsItem.fromJson(json);
      expect(restored.itemId, 'm5');
      expect(restored.ef, 2.8);
      expect(restored.reps, 3);
      expect(restored.interval, 10);
      expect(restored.nextReviewAt, now + 86400000);
      expect(restored.errors, 2);
      expect(restored.createdAt, now - 86400000);
      expect(restored.lastReviewedAt, now);
    });

    test('fromJson with partial data uses defaults', () {
      final item = SrsItem.fromJson({'itemId': 'p1'});
      expect(item.ef, 2.5);
      expect(item.reps, 0);
      expect(item.errors, 0);
    });

    test('copyWith updates only specified fields', () {
      final item = const SrsItem(itemId: 'm5', type: 'flashcard', ef: 2.6, reps: 2, interval: 6);
      final updated = item.copyWith(ef: 2.8, errors: 1);
      expect(updated.ef, 2.8);
      expect(updated.errors, 1);
      expect(updated.reps, 2); // unchanged
      expect(updated.interval, 6); // unchanged
    });
  });
}
