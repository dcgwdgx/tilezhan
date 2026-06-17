/// ProfileScreen 个人中心页面的 Widget 测试
/// 测试覆盖：页面标题渲染、统计标签显示、账户区域展示
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/profile/presentation/profile_screen.dart';

void main() {
  group('ProfileScreen', () {
    // 页面渲染个人资料标题
    testWidgets('renders profile header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      await tester.pump();
      expect(find.text('Profile'), findsOneWidget);
    });

    // 显示 ELO 和 Streak 统计标签
    testWidgets('shows stat labels', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Stats may show defaults since storage isn't available
      expect(find.text('ELO'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
    });

    // 显示 ACCOUNT 分区标题
    testWidgets('shows account section', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ProfileScreen())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ACCOUNT'), findsOneWidget);
    });
  });
}
