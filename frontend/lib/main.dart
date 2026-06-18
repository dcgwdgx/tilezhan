/// TileSlash app entry point — Hive init, Riverpod, routing, l10n.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('prefs');
  await Hive.openBox('hearts');
  await Hive.openBox('yaku_favorites');
  localeModel.init();
  runApp(const ProviderScope(child: TileSlashApp()));
}

class TileSlashApp extends StatelessWidget {
  const TileSlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeModel,
      builder: (context, _) => MaterialApp.router(
        key: ValueKey(localeModel.locale.languageCode),
        title: 'TileSlash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: localeModel.locale,
      ),
    );
  }
}
