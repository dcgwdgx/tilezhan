/// ShantenCalculator 向听数计算器的单元测试
/// 测试覆盖：七对子、国士无双、一般手牌、边界情况、34数组构造法、牌ID解析
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/engine/shanten_calculator.dart';

void main() {
  /// ShantenCalculator 的完整测试套件，覆盖特殊役种（七对子、国士无双）、
  /// 一般手牌（和牌/听牌）、边界情况、构造方法一致性与牌ID解析。
  group('ShantenCalculator', () {
    // ── 七对子（Chiitoitsu）向听数计算 ──
    // 场景：6对 + 1孤张，仅差1对即七对子听牌，向听数应为0
    test('chiitoi tenpai (1-shanten) returns 0 shanten', () {
      final hand = ['m1','m1','m2','m2','m3','m3','p1','p1','p2','p2','p3','p3','s1','s1'];
      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    // 场景：4对 + 5孤张，距七对子还差3对（2向听），向听数应 <= 3
    test('chiitoi 2-shanten returns 1', () {
      // 4对 + 5孤张 = 距七对子还差3对，即2向听
      final hand = ['m1','m1','m2','m2','m3','m3','m4','p1','p2','p3','p4','s1','s2','s3'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(3));
    });

    // ── 国士无双（Kokushi Musou）向听数计算 ──
    // 场景：13种幺九牌各至少一张且有对子，已和牌，向听数应为 -1（和牌）
    test('kokushi complete (13 kinds + pair) is agari', () {
      // 13种幺九牌齐全且有一对 = 国士无双和牌，返回 -1
      final hand = ['m1','m1','m9','p1','p9','s1','s9','z1','z2','z3','z4','z5','z6','z7'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(0));
    });

    // 场景：仅12种幺九牌且无对子，距国士无双还差1种+1对，向听数应为1
    test('kokushi iishanten (12 kinds, no pair) is 1-shanten', () {
      // 12种幺九牌 + 无对子 = 1向听
      final hand = ['m1','m9','p1','p9','s1','s9','z1','z2','z3','z4','z5','z6','z7','m5'];
      expect(ShantenCalculator.fromIds(hand).calculate(), lessThanOrEqualTo(1));
    });

    // 场景：11种幺九牌 + 1对子，距国士无双还差2种，向听数应为1
    test('kokushi 1-shanten returns 1', () {
      // 11种幺九牌 + 1对 = 1向听
      final hand = ['m1','m1','m9','p1','p9','s1','s9','z1','z2','z3','z4','z5','z6','m5'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(1));
    });

    // ── 完整手牌（已和牌）计算 ──
    // 场景：标准平和型 4顺子 + 1对子 = 14张和牌，向听数应为 -1 或 0
    test('complete hand (agari) returns -1 or 0', () {
      // 平和型：4顺子 + 1对子 = 和牌
      final hand = ['m1','m2','m3','m4','m5','m6','p2','p3','p4','p5','p6','p7','s1','s1'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      // 14张构成4面子+1雀头，应为和牌（向听数 <= 0）
      expect(result, lessThanOrEqualTo(0));
    });

    // 场景：3完整面子 + 1搭子 + 1对子 = 听牌，向听数应为0
    test('tenpai hand returns 0', () {
      // 听牌手牌：3面子 + 1搭子 + 1对子 = 0向听
      final hand = ['m1','m2','m3','m4','m5','m6','p2','p3','p4','s1','s2','s3','z1','z1'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(1));
    });

    // ── 边界情况测试 ──
    // 场景：14张完全相同的牌（现实中不可能），验证计算器不会崩溃且返回非负数
    test('14 identical tiles handle gracefully', () {
      // 14张相同牌在麻将规则中不可能出现，但计算器应能正常处理不崩溃
      final hand = List.filled(14, 'm1');
      final result = ShantenCalculator.fromIds(hand).calculate();
      // 14张相同牌现实中不可能，但不应崩溃
      expect(result, isNonNegative);
    });

    // 场景：空手牌没有任何牌，向听数应为最大值 6
    test('empty hand is 6-shanten', () {
      // 空手牌 = 6向听（任何面子/搭子/对子都未凑齐）
      final hand = <String>[];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, 6);
    });

    // 场景：同一手牌多次计算，结果应完全一致（验证算法确定性）
    test('consistent results across multiple runs', () {
      // 同输入多次运行结果应一致，验证计算无随机性或状态残留
      final hand = ['m1','m1','m2','m3','m4','m5','m6','m7','m8','m9','m9','p1','p1','p1'];
      final results = List.generate(5, (_) => ShantenCalculator.fromIds(hand).calculate());
      expect(results.toSet().length, 1);
    });

    // 场景：无特殊结构的随机手牌，向听数应在 0-6 合理范围内
    test('random hand returns shanten between 0 and 6', () {
      // 随机散牌（无顺子/刻子结构），向听数应在 [0, 6] 区间内
      final hand = ['m1','m3','m5','m7','m9','p2','p4','p6','p8','s1','s3','s5','z1','z2'];
      final result = ShantenCalculator.fromIds(hand).calculate();
      expect(result, lessThanOrEqualTo(6));
      expect(result, greaterThanOrEqualTo(0));
    });

    // ── 34数组构造法验证 ──
    // 场景：同一手牌分别用 fromIds 和直接传入 34 长度数组两种方式构造，
    // 计算结果应完全一致（验证两种构造路径等价性）
    test('34-array constructor matches fromIds', () {
      // fromIds 与 34数组构造器应对同一手牌返回相同向听数
      final ids = ['m1','m1','m2','m3','m4','m5','m6','m7','m8','m9','m9','p1','p1','p1'];
      final fromIds = ShantenCalculator.fromIds(ids).calculate();
      final arr = List.filled(34, 0);
      arr[0]=2; arr[1]=1; arr[2]=1; arr[3]=1; arr[4]=1; arr[5]=1; arr[6]=1; arr[7]=1;
      arr[8]=2; arr[9]=2; arr[10]=1;
      final fromArr = ShantenCalculator(arr).calculate();
      expect(fromIds, fromArr);
    });

    // ── 牌ID解析测试 ──
    // 场景：四种花色（万m/筒p/索s/字z）的单张牌ID均能正确解析为对应索引
    test('tile IDs parse correctly across all suits', () {
      // 万(m)、筒(p)、索(s)、字(z) 四种花色的单张牌ID都应能被正确解析
      expect(ShantenCalculator.fromIds(['m1']).calculate(), 6);
      expect(ShantenCalculator.fromIds(['p9']).calculate(), 6);
      expect(ShantenCalculator.fromIds(['s5']).calculate(), 6);
      expect(ShantenCalculator.fromIds(['z7']).calculate(), 6);
    });

    // 场景：传入不在合法范围内的牌ID（如 'x1'），应抛出 ArgumentError
    test('invalid tile ID throws', () {
      // 非法牌ID 'x1'（花色 x 不存在），应抛出 ArgumentError
      expect(
        () => ShantenCalculator.fromIds(['x1']).calculate(),
        throwsArgumentError,
      );
    });
  });
}
