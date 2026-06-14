import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// TileSlash 应用入口。
///
/// 启动流程：
/// 1. 绑定 Flutter 引擎 + 初始化 Hive 本地存储
/// 2. 挂载 [ProviderScope] 作为顶层 Riverpod 容器
/// 3. 启动 [TileSlashApp]（MaterialApp.router + 暗色主题 + 声明式路由）

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: TileSlashApp()));
}

/// 应用的根 Widget。
///
/// 使用 [MaterialApp.router] 绑定声明式路由（[appRouter]），
/// 统一暗色主题 ([AppTheme.dark])，关闭 debug 横幅。
class TileSlashApp extends StatelessWidget {
  const TileSlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TileSlash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
