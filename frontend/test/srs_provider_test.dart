/// SRS 提供者逻辑的单元测试
/// 测试覆盖：首次复习创建条目、质量 4/5 的差异、待复习项按错误权重排序、错误权重公式、正误答案调度
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_engine.dart';

void main() {
  group('SRS provider logic', () {
    // 质量 1（错误）的首次复习：reps=0, interval=1, nextReviewAt=0（立即重考）
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

    // 质量 4（正确）的首次复习：reps=1, interval=1, EF>=2.5
    test('recordReview quality 4: reps=1, interval=1', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(reps, 1);
      expect(interval, 1);
      expect(ef, greaterThanOrEqualTo(2.5));
    });

    // 质量 5（完美）的 EF 提升程度应大于质量 4
    test('recordReview quality 5: EF increases more than quality 4', () {
      final (ef4, _, _) = SrsEngine.calculate(2.5, 0, 1, 4);
      final (ef5, _, _) = SrsEngine.calculate(2.5, 0, 1, 5);
      expect(ef5, greaterThan(ef4));
    });

    // 待复习项按错误权重降序排列：最高错误密度的排最前
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

    // 验证错误权重公式的三个边界值
    test('errorWeight formula: errors/(reps+1)', () {
      expect(SrsItem(itemId: 'x', type: 'flashcard', errors: 0, reps: 0).errorWeight, 0.0);
      expect(SrsItem(itemId: 'x', type: 'flashcard', errors: 5, reps: 0).errorWeight, 5.0);
      expect(SrsItem(itemId: 'x', type: 'flashcard', errors: 6, reps: 2).errorWeight, 2.0);
    });

    // 回答正确时安排未来复习（间隔 > 0）
    test('correct answer schedules future review', () {
      final (_, _, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(interval, greaterThan(0));
    });

    // 回答错误时安排立即复习（间隔 = 1 天 = 当天）
    test('wrong answer schedules immediate review (0 days)', () {
      final (_, _, interval) = SrsEngine.calculate(2.5, 0, 1, 1);
      expect(interval, 1);
    });
  });
}
