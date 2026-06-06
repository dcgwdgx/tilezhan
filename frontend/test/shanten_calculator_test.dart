import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/engine/shanten_calculator.dart';

void main() {
  group('ShantenCalculator', () {
    test('chiitoi tenpai returns 0', () {
      final hand = ['m1','m1','m2','m2','m3','m3','p1','p1','p2','p2','p3','p3','s1','s1'];
      expect(ShantenCalculator.fromIds(hand).calculate(), 0);
    });

    test('consistent results', () {
      final hand = ['m1','m1','m2','m3','m4','m5','m6','m7','m8','m9','m9','p1','p1','p1'];
      final results = List.generate(5, (_) => ShantenCalculator.fromIds(hand).calculate());
      expect(results.toSet().length, 1);
    });

    test('random hand returns shanten <= 6', () {
      final hand = ['m1','m3','m5','m7','m9','p2','p4','p6','p8','s1','s3','s5','z1','z2'];
      expect(ShantenCalculator.fromIds(hand).calculate(), lessThanOrEqualTo(6));
    });

    test('34-array constructor matches fromIds', () {
      final ids = ['m1','m1','m2','m3','m4','m5','m6','m7','m8','m9','m9','p1','p1','p1'];
      final fromIds = ShantenCalculator.fromIds(ids).calculate();
      final arr = List.filled(34, 0);
      arr[0]=2; arr[1]=1; arr[2]=1; arr[3]=1; arr[4]=1; arr[5]=1; arr[6]=1; arr[7]=1;
      arr[8]=2; arr[9]=2; arr[10]=1;
      final fromArr = ShantenCalculator(arr).calculate();
      expect(fromIds, fromArr);
    });
  });
}
