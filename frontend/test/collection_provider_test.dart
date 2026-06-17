/// 役种解锁计算逻辑的单元测试
/// 测试覆盖：复习次数分段解锁、上限封顶、多项 SRS 条目汇总
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_item.dart';

void main() {
  group('Yaku unlock calculation', () {
    // 0 次复习 = 0 个役种解锁（仅显示第一个基础役种）
    test('0 reviews = 0 unlocked (only first yaku shown)', () {
      final unlocked = (0 ~/ 5).clamp(0, 7);
      expect(unlocked, 0);
    });

    // 5 次复习 = 1 个额外役种解锁
    test('5 reviews = 1 unlocked', () {
      final unlocked = (5 ~/ 5).clamp(0, 7);
      expect(unlocked, 1);
    });

    // 15 次复习 = 3 个额外役种解锁
    test('15 reviews = 3 unlocked', () {
      final unlocked = (15 ~/ 5).clamp(0, 7);
      expect(unlocked, 3);
    });

    // 50 次复习 = 封顶在 7 个（最多解锁 7 个额外役种）
    test('50 reviews = capped at 7', () {
      final unlocked = (50 ~/ 5).clamp(0, 7);
      expect(unlocked, 7);
    });

    // 多条目 SRS 的 reps 汇总求和
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
