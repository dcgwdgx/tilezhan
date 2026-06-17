/// SrsEngine SM-2 间隔重复算法的单元测试
/// 测试覆盖：首次完美回忆、失败重置、渐进递增、EF 下限、质量等级映射、确定性验证
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/srs/srs_engine.dart';

void main() {
  /// SrsEngine SM-2 间隔重复算法单元测试分组
  /// 覆盖：首次完美回忆、失败重置、渐进递增、EF 下限保护、质量等级映射、确定性验证
  group('SrsEngine — SM-2 algorithm', () {
    // ── 新牌首次完美回忆 ──
    // 质量 5（完美+助记符）：interval=1, reps=1, EF 从 2.5 提升
    test('first perfect recall (q=5): interval=1, reps=1, ef>2.5', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 5);
      expect(reps, 1);
      expect(interval, 1);
      expect(ef, greaterThan(2.5));
    });

    // 质量 4（正确）：interval=1, reps=1
    test('first perfect recall (q=4): interval=1, reps=1', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(reps, 1);
      expect(interval, 1);
    });

    // 质量 3（犹豫但正确）：EF 可能下降，但受限于 1.3 下限
    test('first hesitant recall (q=3): interval=1, reps=1, EF may decrease', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 3);
      expect(reps, 1);
      expect(interval, 1);
      expect(ef, greaterThanOrEqualTo(1.3)); // EF floor applies
    });

    // ── 回忆失败 —— 重置进度 ──
    // 质量 2（接近失败）：reps 重置为 0，interval 重置为 1
    test('failed recall (q=2): reps reset to 0, interval reset to 1', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 3, 6, 2);
      expect(reps, 0);
      expect(interval, 1);
    });

    // 质量 0（完全忘记/超时）：reps=0, interval=1, EF 不变
    test('complete blackout (q=0): reps=0, interval=1, EF unchanged', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.5, 5, 10, 0);
      expect(reps, 0);
      expect(interval, 1);
      expect(ef, 2.5); // EF preserved on fail
    });

    // 质量 2（临界失败）：EF 不变，reps 重置
    test('borderline fail (q=2): EF preserved, reps=0', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.8, 4, 8, 2);
      expect(reps, 0);
      expect(interval, 1);
      expect(ef, 2.8); // EF unchanged
    });

    // ── 渐进复习间隔 ──
    // 第二次完美回忆（reps 1→2）：interval 跳到 6 天
    test('second perfect recall (reps 1→2): interval=6', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.6, 1, 1, 5);
      expect(reps, 2);
      expect(interval, 6);
    });

    // 第三次完美回忆：interval = 上次 interval × EF
    test('third perfect recall: interval = prev_interval × ef', () {
      final (ef, reps, interval) = SrsEngine.calculate(2.6, 2, 6, 5);
      expect(reps, 3);
      expect(interval, (6 * ef).round());
    });

    // ── EF 下限保护 ──
    // 连续 20 次质量 3 的复习后 EF 不得低于 1.3
    // 模拟连续低质量回忆场景，验证 EF 下限 1.3 的硬保护
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

    // ── 应用场景质量映射 ──
    // 质量 5（正确 + 查看助记符）→ 间隔正常递增
    test('quality 5 (correct + mnemonic) → interval advances', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 5);
      expect(reps, 1);
      expect(interval, 1);
    });

    // 质量 4（正确未看助记符）→ 间隔正常递增
    test('quality 4 (correct) → interval advances', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 0, 1, 4);
      expect(reps, 1);
      expect(interval, 1);
    });

    // 质量 1（错误）→ 重置进度
    test('quality 1 (wrong) → reset', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 5, 20, 1);
      expect(reps, 0);
      expect(interval, 1);
    });

    // 质量 0（超时未答）→ 重置进度
    test('quality 0 (timeout) → reset', () {
      final (_, reps, interval) = SrsEngine.calculate(2.5, 5, 20, 0);
      expect(reps, 0);
      expect(interval, 1);
    });

    // ── 确定性验证 ──
    // 相同输入多次计算必须得到相同结果（纯函数）
    test('same inputs produce same outputs', () {
      final a = SrsEngine.calculate(2.5, 3, 10, 4);
      final b = SrsEngine.calculate(2.5, 3, 10, 4);
      expect(a.$1, b.$1);
      expect(a.$2, b.$2);
      expect(a.$3, b.$3);
    });
  });
}
