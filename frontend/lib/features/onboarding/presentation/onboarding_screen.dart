/// TileZhan onboarding / walkthrough screen.
///
/// Displays a multi-step introduction to the app — swipe-to-learn tile
/// recognition, visual mnemonics for all 34 mahjong tiles, and the discard
/// efficiency mechanic — before handing off to the main experience.
/// Navigates forward through [OnboardingScreen._steps] via dot indicators
/// and a next button; the final step opens the first three-card lesson.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../training_plan/data/training_plan_store.dart';

final onboardingCompletionWriterProvider =
    Provider<Future<void> Function()>((ref) {
  return () async {
    await Hive.box('prefs').put('onboarding_complete', true);
  };
});

/// Full-screen onboarding walkthrough widget.
///
/// Managed by the [GoRouter] dispatcher at the `/onboarding` route (if any).
/// Conveys the core value propositions in 3 swipe-free steps with rich
/// emoji, titles, and descriptions. Animates a dot-stepper at the bottom
/// and offers a skip affordance that jumps directly to `/`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _isStarting = false;
  bool _showSaveError = false;
  static const _totalSteps = 3;

  Future<void> _startFirstLesson() async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
      _showSaveError = false;
    });
    try {
      // Finish generating the zero-history plan before the first answer can
      // enter SRS. Otherwise that answer could incorrectly classify a brand
      // new learner as returning.
      await ref
          .read(dailyTrainingPlanProvider.notifier)
          .flush()
          .timeout(const Duration(seconds: 4));
      await ref.read(onboardingCompletionWriterProvider)();
    } on Object {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _showSaveError = true;
        });
      }
      return;
    }
    if (!mounted) return;
    context.go('/flashcard?source=onboarding&target=3');
  }

  Future<void> _skipOnboarding() async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
      _showSaveError = false;
    });
    try {
      await ref.read(onboardingCompletionWriterProvider)();
    } on Object {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _showSaveError = true;
        });
      }
      return;
    }
    if (mounted) context.go('/');
  }

  List<Map<String, String>> _buildSteps(AppLocalizations l10n) => [
        {
          'emoji': '🀄',
          'title': l10n.onboarding1Title,
          'desc': l10n.onboarding1Desc,
        },
        {
          'emoji': '⚔️',
          'title': l10n.onboarding2Title,
          'desc': l10n.onboarding2Desc,
        },
        {
          'emoji': '🎯',
          'title': l10n.onboarding3Title,
          'desc': l10n.onboarding3Desc,
        },
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = _buildSteps(l10n);
    final step = steps[_step];
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(step['emoji']!, style: const TextStyle(fontSize: 80)),
                    const SizedBox(height: 32),
                    Text(step['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.jadeWhite,
                          height: 1.3,
                        )),
                    const SizedBox(height: 16),
                    Text(step['desc']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.jadeWhiteDim,
                          height: 1.6,
                        )),
                  ],
                ),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  _totalSteps,
                  (i) => Container(
                        width: i == _step ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _step
                              ? AppColors.neonGold
                              : AppColors.jadeHover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
            ),
            const SizedBox(height: 32),
            if (_showSaveError) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  l10n.trainingSaveError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.vermillionHover,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isStarting ? null : _skipOnboarding,
                    child: Text(l10n.onboardingSkip,
                        style:
                            const TextStyle(color: AppColors.jadeWhiteMuted)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isStarting
                        ? null
                        : () {
                            if (_step < _totalSteps - 1) {
                              setState(() => _step++);
                            } else {
                              _startFirstLesson();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vermillion,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isStarting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _step == _totalSteps - 1
                                ? l10n.onboardingStart
                                : l10n.onboardingNext,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
