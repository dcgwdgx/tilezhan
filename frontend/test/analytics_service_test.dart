/// AnalyticsService 分析服务的单元测试
/// 测试覆盖：事件日志记录、屏幕视图辅助方法、答题记录、禁用开关、事件累积
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/analytics/analytics_service.dart';

void main() {
  setUp(() {
    // 每个测试前重置分析服务状态
    AnalyticsService.reset();
  });

  group('AnalyticsService', () {
    // log 将事件及参数添加到缓冲区
    test('log adds event to buffer', () {
      AnalyticsService.log('test_event', {'key': 'value'});
      final events = AnalyticsService.flush();
      expect(events.length, 1);
      expect(events.first.name, 'test_event');
    });

    // screen 辅助方法记录 screen_view 事件
    test('screen helper logs screen_view', () {
      AnalyticsService.screen('home');
      final events = AnalyticsService.flush();
      expect(events.first.name, 'screen_view');
    });

    // answered 辅助方法记录 answer 事件（含对错信息）
    test('answered helper logs answer', () {
      AnalyticsService.answered('flashcard', true);
      final events = AnalyticsService.flush();
      expect(events.first.name, 'answer');
    });

    // 禁用后不再记录任何事件
    test('disable stops logging', () {
      AnalyticsService.disable();
      AnalyticsService.log('should_not_appear');
      final events = AnalyticsService.flush();
      expect(events, isEmpty);
    });

    // 多次 log 按顺序累积在缓冲区中
    test('multiple events accumulate', () {
      AnalyticsService.log('e1');
      AnalyticsService.log('e2');
      AnalyticsService.log('e3');
      final events = AnalyticsService.flush();
      expect(events.length, 3);
    });
  });
}
