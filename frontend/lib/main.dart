import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/time_service.dart';
import 'core/storage/isar_service.dart';
import 'core/storage/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (enable when frontend Firebase project ready)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await IsarService.initialize();
  await HiveService.initialize();
  await TimeService.sync();

  runApp(const ProviderScope(child: TileZhanApp()));
}

class TileZhanApp extends StatelessWidget {
  const TileZhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TileZhan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}

