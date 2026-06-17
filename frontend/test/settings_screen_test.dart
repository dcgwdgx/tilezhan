/// SettingsScreen 设置页面的 Widget 测试
/// 测试覆盖：标题渲染、学习分区、账户分区、关于分区及版本号
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tilezhan/features/settings/presentation/settings_screen.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_settings');
    await Hive.openBox('prefs');
    Hive.box('prefs').put('app_language', 'en');
  });

  group('SettingsScreen', () {
    // 页面标题正确渲染
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const SettingsScreen(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')])));
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
    });

    // 显示 LEARNING 分区标题
    testWidgets('shows learning section', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const SettingsScreen(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')])));
      await tester.pump();
      expect(find.text('LEARNING'), findsOneWidget);
    });

    // 显示 ACCOUNT 分区标题
    testWidgets('shows account section', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const SettingsScreen(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')])));
      await tester.pump();
      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    // 显示 ABOUT 分区及版本号 1.0.0+1
    testWidgets('shows about section with version', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const SettingsScreen(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')])));
      await tester.pump();
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('1.0.0+1'), findsOneWidget);
    });
  });
}
