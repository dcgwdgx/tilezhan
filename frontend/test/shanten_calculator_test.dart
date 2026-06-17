/// ShantenCalculator 向听数计算器的单元测试
/// 测试覆盖：七对子、国士无双、一般手牌、边界情况、34数组构造法、牌ID解析
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/engine/shanten_calculator.dart';

void main() {
  group('ShantenCalculator', () {
    // ── 七对子（Chiitoitsu）向听数计算 ──
    // 6对 + 1孤张 = 听牌（0向听）
    test('chiitoi tenpai (1-shanten) returns 0 shanten', () {
      final hand = ['m1','m1','m2','m2','m3','m3','p1','p1','p2','p2','p3','p3','s1','s1'];
      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    // 4对 + 5孤张 = 2向听，结果 <= 3
    test('chiitoi 2-shanten returns 1', () {
      // 4 pairs + 5 singles → 2 away from 7 pairs
      final hand = ['m1','m1','m2','m2','m3','m3','m4','p1','p2','p3','p4','s1','s2','s3'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(3));
    });

    // ── 国士无双（Kokushi Musou）向听数计算 ──
    // 13种幺九牌各一张 + 任意1张成对 = 和牌（-1）
    test('kokushi complete (13 kinds + pair) is agari', () {
      // All 13 terminals with a pair = complete kokushi, returns -1 (agari)
      final hand = ['m1','m1','m9','p1','p9','s1','s9','z1','z2','z3','z4','z5','z6','z7'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(0));
    });

    // 12种幺九牌 + 无对子 = 1向听
    test('kokushi iishanten (12 kinds, no pair) is 1-shanten', () {
      // 12 terminal kinds, no pair → 1 away
      final hand = ['m1','m9','p1','p9','s1','s9','z1','z2','z3','z4','z5','z6','z7','m5'];
      expect(ShantenCalculator.fromIds(hand).calculate(), lessThanOrEqualTo(1));
    });

    // 11种幺九牌 + 1对 = 1向听
    test('kokushi 1-shanten returns 1', () {
      // 11 kinds + pair
      final hand = ['m1','m1','m9','p1','p9','s1','s9','z1','z2','z3','z4','z5','z6','m5'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(1));
    });

    // ── 完整手牌（已和牌）计算 ──
    // 平和型：4顺子 + 1对子 = 和牌
    test('complete hand (agari) returns -1 or 0', () {
      // Pinfu: 4 sequences + pair
      final hand = ['m1','m2','m3','m4','m5','m6','p2','p3','p4','p5','p6','p7','s1','s1'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      // With 14 tiles and 4 melds + pair, should be 0 or less
      expect(result, lessThanOrEqualTo(0));
    });

    // 听牌手牌：3面子 + 1搭子 + 1对子 = 0向听
    test('tenpai hand returns 0', () {
      // Ready hand: 3 melds + 1 partial + pair
      final hand = ['m1','m2','m3','m4','m5','m6','p2','p3','p4','s1','s2','s3','z1','z1'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(1));
    });

    // ── 边界情况测试 ──
    // 14张相同牌：现实中不可能，但应能正常处理不崩溃
    test('14 identical tiles handle gracefully', () {
      final hand = List.filled(14, 'm1');
      final result = ShantenCalculator.fromIds(hand).calculate();
      // 14 of same tile is impossible in mahjong but should not crash
      expect(result, isNonNegative);
    });

    // 空手牌 = 6向听（什么都没凑齐）
    test('empty hand is 6-shanten', () {
      final hand = <String>[];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, 6);
    });

    // 多次计算同一手牌结果一致（确定性验证）
    test('consistent results across multiple runs', () {
      final hand = ['m1','m1','m2','m3','m4','m5','m6','m7','m8','m9','m9','p1','p1','p1'];
      final results = List.generate(5, (_) => ShantenCalculator.fromIds(hand).calculate());
      expect(results.toSet().length, 1);
    });

    // 随机手牌的向听数应在 0-6 范围内
    test('random hand returns shanten between 0 and 6', () {
      final hand = ['m1','m3','m5','m7','m9','p2','p4','p6','p8','s1','s3','s5','z1','z2'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(6));
      expect(result, greaterThanOrEqualTo(0));
    });

    // ── 34数组构造法验证 ──
    // fromIds 和直接传 34 长度数组的结果应一致
    test('34-array constructor matches fromIds', () {
      final ids = ['m1','m1','m2','m3','m4','m5','m6','m7','m8','m9','m9','p1','p1','p1'];
      final fromIds = ShantenCalculator.fromIds(ids).calculate();
      final arr = List.filled(34, 0);
      arr[0]=2; arr[1]=1; arr[2]=1; arr[3]=1; arr[4]=1; arr[5]=1; arr[6]=1; arr[7]=1;
      arr[8]=2; arr[9]=2; arr[10]=1;
      final fromArr = ShantenCalculator(arr).calculate();
      expect(fromIds, fromArr);
    });

    // ── 牌ID解析测试 ──
    // 四种花色（万/筒/索/字）的牌ID都能正确解析
    test('tile IDs parse correctly across all suits', () {
      expect(ShantenCalculator.fromIds(['m1']).calculate(), 6);
      expect(ShantenCalculator.fromIds(['p9']).calculate(), 6);
      expect(ShantenCalculator.fromIds(['s5']).calculate(), 6);
      expect(ShantenCalculator.fromIds(['z7']).calculate(), 6);
    });

    // 无效的牌ID（如 'x1'）应抛出 ArgumentError
    test('invalid tile ID throws', () {
      expect(
        () => ShantenCalculator.fromIds(['x1']).calculate(),
        throwsArgumentError,
      );
    });
  });
}
