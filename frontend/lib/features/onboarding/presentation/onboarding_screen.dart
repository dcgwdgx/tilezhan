import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 3;

  final _steps = const [
    {
      'emoji': '🀄',
      'title': 'Master Mahjong\nthe Smart Way',
      'desc': 'Like flashcards, but for the world\'s\nmost addictive mind game.',
    },
    {
      'emoji': '🃏',
      'title': 'Swipe to Learn',
      'desc': 'Recognize all 34 tiles instantly\nwith visual mnemonics.\n0.5 second per card.',
    },
    {
      'emoji': '⚔️',
      'title': 'Slice to Win',
      'desc': 'Learn which tile to discard\nfor maximum efficiency.\nOne slash at a time.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
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
                    Text(step['title']!, textAlign: TextAlign.center, style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.jadeWhite,
                      height: 1.3,
                    )),
                    const SizedBox(height: 16),
                    Text(step['desc']!, textAlign: TextAlign.center, style: const TextStyle(
                      fontSize: 15, color: AppColors.jadeWhiteDim, height: 1.6,
                    )),
                  ],
                ),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalSteps, (i) => Container(
                width: i == _step ? 24 : 8, height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _step ? AppColors.neonGold : AppColors.jadeHover,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Skip', style: TextStyle(color: AppColors.jadeWhiteMuted)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_step < _totalSteps - 1) {
                        setState(() => _step++);
                      } else {
                        context.go('/');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vermillion,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _step == _totalSteps - 1 ? 'GET STARTED' : 'NEXT →',
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
