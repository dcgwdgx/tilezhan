/// GoRouter 路由配置，定义应用全屏页面的路径映射与转场动画。
///
/// 每个路由使用统一的 [CustomTransitionPage] 包装，提供从右向左滑入
/// 并伴随淡入的 200ms 过渡效果。路由按扁平结构组织，覆盖启动、引导、
/// 主页、闪卡、何切、牌览、收藏、牌河、高级版、扫码、个人中心、设置
/// 共计 12 个全屏页面。
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

/// 应用全局路由实例，12 条全屏页面路由的扁平映射。
///
/// 初始位置为 `/splash`。每条路由通过 [_page] 构建统一的转场动画页。
/// `/flashcard` 路由支持 `suite` 查询参数以指定牌组。
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
