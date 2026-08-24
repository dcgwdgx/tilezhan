import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/commerce/commerce_availability.dart';
import 'package:tilezhan/core/hearts/heart_provider.dart';
import 'package:tilezhan/core/hearts/heart_service.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';
import 'package:tilezhan/core/providers/storage_provider.dart';
import 'package:tilezhan/core/storage/storage_service.dart';
import 'package:tilezhan/features/home/presentation/home_screen.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

class _FakeHeartService extends HeartService {
  _FakeHeartService(this._hearts);

  final int _hearts;

  @override
  int get hearts => _hearts;

  @override
  bool get hasHearts => _hearts > 0;

  @override
  Future<void> init() async {}
}

class _FakeIapService implements IapService {
  @override
  IapState get state => const IapState(status: IapStatus.ready);

  @override
  Stream<IapState> get stateStream => const Stream<IapState>.empty();

  @override
  Future<void> init() async {}

  @override
  Future<void> purchase(String productId) async {}

  @override
  Future<void> restore() async {}

  @override
  void dispose() {}
}

class _FixedDailyTrainingPlanNotifier extends DailyTrainingPlanNotifier {
  _FixedDailyTrainingPlanNotifier(this._plan);

  final DailyTrainingPlan _plan;

  @override
  DailyTrainingPlan? build() => _plan;
}

DailyTrainingPlan _todayPlan() => DailyTrainingPlan(
      localDate: DateTime(2026, 8, 24),
      currentStreak: 4,
      bestStreak: 7,
      lastCompletedDate: '2026-08-23',
      tasks: [
        TrainingPlanTask(
          id: 'starter:flashcard',
          kind: TrainingTaskKind.starterLesson,
          module: TrainingModule.flashcard,
          targetAttempts: 3,
          completedAttempts: 1,
        ),
        TrainingPlanTask(
          id: 'explore:yaku',
          kind: TrainingTaskKind.exploration,
          module: TrainingModule.yaku,
          targetAttempts: 3,
        ),
        TrainingPlanTask(
          id: 'daily:nanikiru',
          kind: TrainingTaskKind.dailyChallenge,
          module: TrainingModule.nanikiru,
          targetAttempts: 3,
        ),
      ],
    );

class _HomeHarness {
  _HomeHarness({
    this.trainingLimitsEnabled = false,
    this.hearts = 7,
  });

  final bool trainingLimitsEnabled;
  final int hearts;
  int iapProviderReads = 0;

  Widget build() {
    final plan = _todayPlan();
    final storageNeverCompletes = Completer<StorageService>();
    final heartService = _FakeHeartService(hearts);
    final iapService = _FakeIapService();

    return ProviderScope(
      overrides: [
        commerceAvailabilityProvider.overrideWithValue(
          CommerceAvailability(
            platform: TargetPlatform.android,
            salesEnabled: false,
            trainingLimitsEnabled: trainingLimitsEnabled,
            restoreEnabled: true,
          ),
        ),
        heartServiceProvider.overrideWith((ref) => heartService),
        iapServiceProvider.overrideWith((ref) {
          iapProviderReads++;
          return iapService;
        }),
        storageServiceProvider.overrideWith(
          (ref) => storageNeverCompletes.future,
        ),
        dailyTrainingPlanProvider.overrideWith(
          () => _FixedDailyTrainingPlanNotifier(plan),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: HomeScreen(),
      ),
    );
  }
}

void main() {
  group('HomeScreen free release', () {
    testWidgets('renders the fixed today plan without paid gates',
        (tester) async {
      final harness = _HomeHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('today-training-card')), findsOneWidget);
      expect(find.text("Today's 5-minute plan"), findsOneWidget);
      expect(find.text('1/9 completed'), findsOneWidget);
      expect(find.text('🔥 4-day learning streak'), findsOneWidget);
      expect(find.text('Learn the core tiles'), findsOneWidget);
      expect(find.text('Explore yaku knowledge'), findsOneWidget);
      expect(find.text('Daily efficiency challenge'), findsOneWidget);
      expect(find.text('CONTINUE PLAN'), findsOneWidget);

      expect(find.textContaining('/10'), findsNothing);
      expect(find.textContaining('UPGRADE'), findsNothing);
      expect(find.text('Premium'), findsNothing);
      expect(harness.iapProviderReads, 0);
    });

    testWidgets('keeps the real learning shortcuts and navigation',
        (tester) async {
      final harness = _HomeHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.text('Flashcards'), findsOneWidget);
      expect(find.text('Nani-Kiru'), findsOneWidget);
      expect(find.text('Hand Analyzer'), findsOneWidget);
      expect(find.text('Defense Trainer'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tiles'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows hearts only when training limits are enabled',
        (tester) async {
      final harness = _HomeHarness(trainingLimitsEnabled: true, hearts: 3);

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.text('3/10'), findsOneWidget);
      expect(find.bySemanticsLabel('3 hearts remaining'), findsOneWidget);
      expect(find.textContaining('UPGRADE'), findsNothing);
      expect(find.text('Premium'), findsNothing);
      expect(harness.iapProviderReads, 0);
    });
  });
}
