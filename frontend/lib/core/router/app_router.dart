import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/flashcard/presentation/flashcard_screen.dart';
import '../../features/nanikiru/presentation/nanikiru_screen.dart';
import '../../features/tile_browser/presentation/tile_browser_screen.dart';
import '../../features/collection/presentation/collection_screen.dart';
import '../../features/graveyard/presentation/graveyard_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

CustomTransitionPage _page(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', pageBuilder: (_, state) => _page(const SplashScreen(), state)),
    GoRoute(path: '/onboarding', pageBuilder: (_, state) => _page(const OnboardingScreen(), state)),
    GoRoute(path: '/', pageBuilder: (_, state) => _page(const HomeScreen(), state)),
    GoRoute(path: '/flashcard', pageBuilder: (_, state) => _page(
      FlashcardScreen(suite: state.uri.queryParameters['suite'] ?? 'all'), state)),
    GoRoute(path: '/nanikiru', pageBuilder: (_, state) => _page(const NanikiruScreen(), state)),
    GoRoute(path: '/tiles', pageBuilder: (_, state) => _page(const TileBrowserScreen(), state)),
    GoRoute(path: '/collection', pageBuilder: (_, state) => _page(const CollectionScreen(), state)),
    GoRoute(path: '/graveyard', pageBuilder: (_, state) => _page(const GraveyardScreen(), state)),
    GoRoute(path: '/premium', pageBuilder: (_, state) => _page(const PremiumScreen(), state)),
    GoRoute(path: '/scanner', pageBuilder: (_, state) => _page(const ScannerScreen(), state)),
    GoRoute(path: '/profile', pageBuilder: (_, state) => _page(const ProfileScreen(), state)),
    GoRoute(path: '/settings', pageBuilder: (_, state) => _page(const SettingsScreen(), state)),
  ],
);
