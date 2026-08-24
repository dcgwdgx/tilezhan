import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/commerce/commerce_availability.dart';
import 'package:tilezhan/core/iap/iap_provider.dart';
import 'package:tilezhan/core/iap/iap_service.dart';
import 'package:tilezhan/core/providers/storage_provider.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/core/srs/srs_provider.dart';
import 'package:tilezhan/core/storage/storage_service.dart';
import 'package:tilezhan/features/profile/presentation/profile_screen.dart';
import 'package:tilezhan/features/training_plan/data/training_plan_store.dart';
import 'package:tilezhan/features/training_plan/domain/training_plan.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';

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

class _ProfileHarness {
  int iapProviderReads = 0;

  Widget build() {
    final plan = _todayPlan();
    final storageNeverCompletes = Completer<StorageService>();
    final iapService = _FakeIapService();

    return ProviderScope(
      overrides: [
        commerceAvailabilityProvider.overrideWithValue(
          const CommerceAvailability(
            platform: TargetPlatform.android,
            salesEnabled: false,
            trainingLimitsEnabled: false,
            restoreEnabled: true,
          ),
        ),
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
        dueItemsProvider.overrideWithValue([
          SrsItem(
            itemId: 'due-one',
            type: 'flashcard',
            nextReviewAt: 0,
          ),
          SrsItem(
            itemId: 'due-two',
            type: 'yaku',
            nextReviewAt: 0,
          ),
        ]),
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
        home: ProfileScreen(),
      ),
    );
  }
}

void _useTallTestSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  group('ProfileScreen local learning profile', () {
    testWidgets('shows only values backed by local learning state',
        (tester) async {
      _useTallTestSurface(tester);
      final harness = _ProfileHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.text('Learning Profile'), findsOneWidget);
      expect(
        find.text('Your learning progress is stored on this device.'),
        findsOneWidget,
      );
      expect(find.text('Skill rating'), findsOneWidget);
      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('Best streak'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Streak'), findsNothing);
      expect(harness.iapProviderReads, 0);
    });

    testWidgets('shows the same today plan progress and real review queue',
        (tester) async {
      _useTallTestSurface(tester);
      final harness = _ProfileHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.text('LEARNING PROGRESS'), findsOneWidget);
      expect(find.text("Today's plan"), findsOneWidget);
      expect(find.text('1/9 activities completed'), findsOneWidget);
      expect(find.text('Review queue'), findsOneWidget);
      expect(find.text('2 due today'), findsOneWidget);
      expect(harness.iapProviderReads, 0);
    });

    testWidgets('keeps restore explicit without exposing an upgrade offer',
        (tester) async {
      _useTallTestSurface(tester);
      final harness = _ProfileHarness();

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(find.text('PREVIOUS PURCHASES'), findsOneWidget);
      expect(find.text('Restore Purchases'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.textContaining('UPGRADE'), findsNothing);
      expect(find.text('Premium'), findsNothing);
      expect(harness.iapProviderReads, 0);
    });
  });
}
