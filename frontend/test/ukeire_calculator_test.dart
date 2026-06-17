/// UkeireCalculator 牌有效率计算器的单元测试
/// 测试覆盖：14 张手牌约束、每张牌的打出结果、向听数与牌有效率、重复牌处理、上限验证
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';

void main() {
  group('UkeireCalculator', () {
    // 必须恰好传入 14 张牌，1 张或 15 张都应抛出异常
    test('requires exactly 14 tiles', () {
      expect(() => UkeireCalculator(['m1']), throwsArgumentError);
      expect(() => UkeireCalculator(List.filled(15, 'm1')), throwsArgumentError);
    });

    // 计算结果包含每种唯一牌的打出分析
    test('returns results for each unique discard', () {
      final hand = ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9','s7'];
      final results = UkeireCalculator(hand).calculate();
      // Should have results for each unique tile type
      expect(results.length, lessThanOrEqualTo(14));
      expect(results.keys, contains('m1'));
    });

    // 每条结果包含向听数、有效牌种类列表、有效牌总数
    test('result has shanten, ukeire types and count', () {
      final hand = ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9','s7'];
      final results = UkeireCalculator(hand).calculate();
      final first = results.values.first;
      expect(first.shantenAfter, isNonNegative);
      expect(first.ukeireTypes, isA<List<String>>());
      expect(first.ukeireCount, isNonNegative);
    });

    // 含有 4 张相同牌的手牌能正常处理不崩溃
    test('handles hands with duplicates correctly', () {
      // Hand with 4 copies of one tile
      final hand = ['m1','m1','m1','m1','m2','m3','m4','m5','m6','p1','p2','p3','p4','p5'];
      final results = UkeireCalculator(hand).calculate();
      // Should not crash
      expect(results, isNotEmpty);
    });

    // 有效牌总数不会超过牌山中剩余牌的数量
    test('ukeire count never exceeds max available tiles', () {
      final hand = ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9','s7'];
      final results = UkeireCalculator(hand).calculate();
      for (final r in results.values) {
        expect(r.ukeireCount, lessThanOrEqualTo(34 * 4 - 14)); // max tiles remaining
      }
    });
  });
}
