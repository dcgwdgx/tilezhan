import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/analytics/analytics_service.dart';

void main() {
  setUp(() {
    AnalyticsService.reset();
  });

  group('AnalyticsService', () {
    test('log adds event to buffer', () {
      AnalyticsService.log('test_event', {'key': 'value'});
      final events = AnalyticsService.flush();
      expect(events.length, 1);
      expect(events.first.name, 'test_event');
    });

    test('screen helper logs screen_view', () {
      AnalyticsService.screen('home');
      final events = AnalyticsService.flush();
      expect(events.first.name, 'screen_view');
    });

    test('answered helper logs answer', () {
      AnalyticsService.answered('flashcard', true);
      final events = AnalyticsService.flush();
      expect(events.first.name, 'answer');
    });

    test('disable stops logging', () {
      AnalyticsService.disable();
      AnalyticsService.log('should_not_appear');
      final events = AnalyticsService.flush();
      expect(events, isEmpty);
    });

    test('multiple events accumulate', () {
      AnalyticsService.log('e1');
      AnalyticsService.log('e2');
      AnalyticsService.log('e3');
      final events = AnalyticsService.flush();
      expect(events.length, 3);
    });
  });
}
