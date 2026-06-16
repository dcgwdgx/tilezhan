/// Splash screen with staggered reveal animation.
///
/// Sequence: emoji fade+scale → title slide-up → tagline → shimmer bar.
/// After 2.5s, checks [onboardingComplete] to decide: /onboarding or /.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _emojiFade, _emojiScale;
  late Animation<double> _titleFade, _titleSlide;
  late Animation<double> _tagFade;

  static bool get onboardingComplete {
    final box = Hive.box('prefs');
    return box.get('onboarding_complete', defaultValue: false);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    // Emoji: fade in + scale bounce (0–0.5s)
    _emojiFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.25, curve: Curves.easeOut)));
    _emojiScale = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.35, curve: Curves.elasticOut)));

    // Title: fade + slide up (0.2–0.7s)
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.15, 0.45, curve: Curves.easeOut)));
    _titleSlide = Tween(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic)));

    // Tagline: fade in (0.4–0.8s)
    _tagFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.6, curve: Curves.easeOut)));

    _ctrl.forward();

    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final target = onboardingComplete ? '/' : '/onboarding';
      context.go(target);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji with glow effect
              Opacity(
                opacity: _emojiFade.value,
                child: Transform.scale(
                  scale: _emojiScale.value,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonGold.withOpacity(0.3 * _emojiFade.value),
                          blurRadius: 40, spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🀄', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title: slide up + fade
              Opacity(
                opacity: _titleFade.value,
                child: Transform.translate(
                  offset: Offset(0, _titleSlide.value),
                  child: const Text('TILEZAN', style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900,
                    letterSpacing: 6, color: AppColors.jadeWhite,
                  )),
                ),
              ),
              const SizedBox(height: 6),
              // Tagline: fade in
              Opacity(
                opacity: _tagFade.value,
                child: const Text('Master Mahjong, One Tile at a Time.',
                  style: TextStyle(fontSize: 13, color: AppColors.neonGold,
                    letterSpacing: 1)),
              ),
              const SizedBox(height: 36),
              // Shimmer progress bar
              SizedBox(
                width: 140, height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.jadeHover,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.vermillion.withOpacity(0.8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
