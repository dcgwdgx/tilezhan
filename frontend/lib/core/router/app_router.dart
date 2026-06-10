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

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/flashcard', builder: (_, state) => FlashcardScreen(
      suite: state.uri.queryParameters['suite'] ?? 'all',
    )),
    GoRoute(path: '/nanikiru', builder: (_, __) => const NanikiruScreen()),
    GoRoute(path: '/tiles', builder: (_, __) => const TileBrowserScreen()),
    GoRoute(path: '/collection', builder: (_, __) => const CollectionScreen()),
    GoRoute(path: '/graveyard', builder: (_, __) => const GraveyardScreen()),
    GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
    GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  ],
);
