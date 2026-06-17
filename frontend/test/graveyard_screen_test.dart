/// GraveyardScreen 牌冢页面（SRS 复习入口）的 Widget 测试
/// 测试覆盖：页面标题、SRS 复习头部、弱点雷达、复习全部按钮
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/graveyard/presentation/graveyard_screen.dart';

void main() {
  group('GraveyardScreen', () {
    // 页面标题 "Tile Graveyard" 正确渲染
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.text('Tile Graveyard'), findsOneWidget);
    });

    // 显示 SRS Review 头部（含幽灵 emoji）
    testWidgets('shows SRS review header', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.text('👻 SRS Review'), findsOneWidget);
    });

    // 显示弱点雷达图区域标题
    testWidgets('shows weakness radar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.text('Weakness Radar'), findsOneWidget);
    });

    // 显示 "Review All" 批复习按钮
    testWidgets('shows review button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GraveyardScreen())),
      );
      await tester.pump();
      expect(find.textContaining('Review All'), findsOneWidget);
    });
  });
}
