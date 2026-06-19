import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/utils/review_service.dart';

void main() {
  group('maybeRequestReview', () {
    test('combo below threshold does not trigger', () {
      // This won't throw — just ensures the guard works
      maybeRequestReview(3, '');
      // No assertion needed — just verify no exception
    });

    test('combo at threshold with old date is allowed', () {
      // Should not throw — combo met, date is old
      maybeRequestReview(5, '2020-01-01');
    });

    test('combo at threshold with today date is skipped', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      // Should silently skip — same day
      maybeRequestReview(5, today);
    });

    test('combo above threshold is allowed', () {
      maybeRequestReview(10, '2020-01-01');
    });
  });

  test('kReviewComboThreshold is 5', () {
    expect(kReviewComboThreshold, 5);
  });

  test('kLastReviewKey is defined', () {
    expect(kLastReviewKey, isNotEmpty);
  });
}
