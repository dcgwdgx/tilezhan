import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilezhan/features/onboarding/presentation/onboarding_screen.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

class _ControlledPlanNotifier extends DailyTrainingPlanNotifier {
  bool shouldFail;
  int flushCalls = 0;

  _ControlledPlanNotifier({required this.shouldFail});

  @override
  DailyTrainingPlan? build() => null;

  @override
  Future<void> flush() async {
    flushCalls += 1;
    if (shouldFail) throw StateError('test save failure');
  }
}

Widget _app(
  _ControlledPlanNotifier notifier, {
  required Future<void> Function() writeCompletion,
}) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Home route')),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/flashcard',
        builder: (_, state) => Scaffold(
          body: Text(
            state.uri.toString(),
            key: const ValueKey('lesson-route'),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  return ProviderScope(
    overrides: [
      dailyTrainingPlanProvider.overrideWith(() => notifier),
      onboardingCompletionWriterProvider.overrideWithValue(writeCompletion),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

Future<void> _reachFinalStep(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.tap(find.text('Next'));
  await tester.pump();
}

void main() {
  testWidgets('first lesson starts only after plan and onboarding are durable',
      (tester) async {
    final notifier = _ControlledPlanNotifier(shouldFail: false);
    var didWriteCompletion = false;
    await tester.pumpWidget(_app(
      notifier,
      writeCompletion: () async {
        didWriteCompletion = true;
      },
    ));
    await tester.pumpAndSettle();
    await _reachFinalStep(tester);

    await tester.tap(find.text('Start First Lesson'));
    await tester.pumpAndSettle();

    expect(notifier.flushCalls, 1);
    expect(didWriteCompletion, isTrue);
    expect(
      find.text('/flashcard?source=onboarding&target=3'),
      findsOneWidget,
    );
  });

  testWidgets('save failure stays retryable instead of entering a stuck lesson',
      (tester) async {
    final notifier = _ControlledPlanNotifier(shouldFail: true);
    var didWriteCompletion = false;
    await tester.pumpWidget(_app(
      notifier,
      writeCompletion: () async {
        didWriteCompletion = true;
      },
    ));
    await tester.pumpAndSettle();
    await _reachFinalStep(tester);

    await tester.tap(find.text('Start First Lesson'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(
      find.text(
        'Your progress could not be saved. Check device storage, then try again.',
      ),
      findsOneWidget,
    );
    expect(didWriteCompletion, isFalse);

    notifier.shouldFail = false;
    await tester.tap(find.text('Start First Lesson'));
    await tester.pumpAndSettle();

    expect(notifier.flushCalls, 2);
    expect(didWriteCompletion, isTrue);
    expect(find.byKey(const ValueKey('lesson-route')), findsOneWidget);
  });
}
