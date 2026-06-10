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
import '../../features/settings/presentation/settings_screen.dart';
import '../constants/app_colors.dart';

/// Shared page transition: fade + right-slide for push, fade + left-slide for pop.
CustomTransitionPage _buildPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const SplashScreen(),
    )),
    GoRoute(path: '/onboarding', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const OnboardingScreen(),
    )),
    GoRoute(path: '/', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const HomeScreen(),
    )),
    GoRoute(path: '/flashcard', pageBuilder: (context, state) => _buildPage(
      context: context, state: state,
      child: FlashcardScreen(suite: state.uri.queryParameters['suite'] ?? 'all'),
    )),
    GoRoute(path: '/nanikiru', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const NanikiruScreen(),
    )),
    GoRoute(path: '/tiles', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const TileBrowserScreen(),
    )),
    GoRoute(path: '/collection', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const CollectionScreen(),
    )),
    GoRoute(path: '/graveyard', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const GraveyardScreen(),
    )),
    GoRoute(path: '/premium', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const PremiumScreen(),
    )),
    GoRoute(path: '/settings', pageBuilder: (context, state) => _buildPage(
      context: context, state: state, child: const SettingsScreen(),
    )),
  ],
);
