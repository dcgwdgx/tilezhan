/// Flutter 测试环境基础冒烟测试
/// 验证 testWidgets 能正常运行，确保测试基础设施可用
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 最简单的基础运算测试，确认测试框架正常工作
  testWidgets('simple math sanity check', (tester) async {
    expect(2 + 2, 4);
  });
}
