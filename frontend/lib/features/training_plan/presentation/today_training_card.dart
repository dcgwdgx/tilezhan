import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../defense_trainer/data/defense_progress_store.dart';
import '../../defense_trainer/domain/defense_progress.dart';
import '../../nanikiru/domain/nanikiru_skill_mastery.dart';
import '../../nanikiru/domain/nanikiru_skill_mastery_provider.dart';
import '../data/training_plan_store.dart';
import '../domain/training_plan.dart';

/// The single primary action on Home: a fixed, explainable plan for today.
class TodayTrainingCard extends ConsumerWidget {
  const TodayTrainingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plan = ref.watch(dailyTrainingPlanProvider);
    final bootstrap =
        plan == null ? ref.watch(trainingPlanBootstrapProvider) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        key: const ValueKey('today-training-card'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3526), Color(0xFF0D3D26)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neonGold.withOpacity(0.28)),
        ),
        child: plan == null
            ? bootstrap?.hasError == true
                ? _buildLoadError(ref, l10n)
                : _buildLoading(l10n)
            : _buildPlan(context, ref, l10n, plan),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n) {
    return Semantics(
      liveRegion: true,
      label: l10n.trainingLoading,
      child: Column(
        children: [
          _Header(
            title: l10n.trainingTodayTitle,
            subtitle: l10n.trainingTodaySubtitle,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: AppColors.neonGold),
          const SizedBox(height: 12),
          Text(
            l10n.trainingLoading,
            style: const TextStyle(color: AppColors.jadeWhiteDim),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError(WidgetRef ref, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: l10n.trainingTodayTitle,
          subtitle: l10n.trainingLoadError,
        ),
        const SizedBox(height: 16),
        TzButton(
          label: l10n.trainingRetry,
          icon: Icons.refresh_rounded,
          style: TzButtonStyle.gold,
          onPressed: () => _retryPlan(ref),
        ),
      ],
    );
  }

  void _retryPlan(WidgetRef ref) {
    ref.invalidate(storageServiceProvider);
    ref.invalidate(srsStoreProvider);
    ref.invalidate(nanikiruSkillMasteryStoreProvider);
    ref.invalidate(defenseProgressStoreProvider);
    ref.invalidate(trainingPlanStoreProvider);
    ref.invalidate(trainingPlanInputsProvider);
    ref.invalidate(trainingPlanBootstrapProvider);
  }

  void _openCurrentTask(BuildContext context, WidgetRef ref) {
    // The app may remain open on Home across local midnight. Refresh at the
    // actual tap boundary and route from the new plan instead of a stale CTA
    // closure captured by yesterday's build.
    ref.read(dailyTrainingPlanProvider.notifier).refreshForToday();
    final currentTask = ref.read(dailyTrainingPlanProvider)?.nextTask;
    if (currentTask != null) context.push(_routeFor(currentTask));
  }

  Widget _buildPlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DailyTrainingPlan plan,
  ) {
    final progressLabel = l10n.trainingPlanProgress(
      plan.completedAttempts,
      plan.targetAttempts,
    );
    final nextTask = plan.nextTask;
    final ctaLabel = plan.isComplete
        ? l10n.trainingPlanComplete
        : plan.completedAttempts == 0
            ? l10n.trainingStartPlan
            : l10n.trainingContinuePlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: l10n.trainingTodayTitle,
          subtitle: l10n.trainingTodaySubtitle,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              plan.currentStreak == 0
                  ? l10n.trainingStreakStart
                  : l10n.trainingLearningStreak(plan.currentStreak),
              style: const TextStyle(
                color: AppColors.neonGold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: progressLabel,
                value: progressLabel,
                child: ExcludeSemantics(
                  child: TzProgressBar(value: plan.progress, height: 6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              progressLabel,
              style: const TextStyle(
                color: AppColors.jadeWhiteDim,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final task in plan.tasks) ...[
          _TaskRow(
            key: ValueKey('training-task-${task.id}'),
            icon: _taskIcon(task),
            title: _taskTitle(l10n, task),
            subtitle: _taskSubtitle(ref, l10n, task),
            progressLabel: l10n.dailyProgress(
              task.completedAttempts,
              task.targetAttempts,
            ),
            complete: task.isComplete,
            active: identical(task, nextTask),
          ),
          if (task != plan.tasks.last) const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        TzButton(
          key: const ValueKey('training-plan-cta'),
          label: ctaLabel,
          icon:
              plan.isComplete ? Icons.check_rounded : Icons.play_arrow_rounded,
          style: TzButtonStyle.gold,
          onPressed:
              nextTask == null ? null : () => _openCurrentTask(context, ref),
        ),
      ],
    );
  }

  IconData _taskIcon(TrainingPlanTask task) => switch (task.kind) {
        TrainingTaskKind.starterLesson => Icons.style_outlined,
        TrainingTaskKind.dueReview => Icons.replay_rounded,
        TrainingTaskKind.weakSkill => Icons.track_changes_rounded,
        TrainingTaskKind.dailyChallenge => Icons.bolt_rounded,
        TrainingTaskKind.exploration => task.module == TrainingModule.defense
            ? Icons.shield_outlined
            : Icons.school_outlined,
      };

  String _taskTitle(AppLocalizations l10n, TrainingPlanTask task) {
    return switch (task.kind) {
      TrainingTaskKind.starterLesson => l10n.trainingTaskStarterTiles,
      TrainingTaskKind.dueReview => l10n.trainingTaskDueReview,
      TrainingTaskKind.weakSkill =>
        l10n.trainingTaskWeakSkill(_skillLabel(l10n, task.focusSkillId)),
      TrainingTaskKind.dailyChallenge => l10n.trainingTaskDailyEfficiency,
      TrainingTaskKind.exploration => task.module == TrainingModule.defense
          ? l10n.trainingTaskExploreDefense
          : l10n.trainingTaskExploreYaku,
    };
  }

  String _taskSubtitle(
    WidgetRef ref,
    AppLocalizations l10n,
    TrainingPlanTask task,
  ) {
    return switch (task.kind) {
      TrainingTaskKind.starterLesson => l10n.trainingTaskStarterDesc,
      TrainingTaskKind.dueReview =>
        l10n.trainingTaskDueDesc(task.targetAttempts),
      TrainingTaskKind.dailyChallenge => l10n.trainingTaskDailyDesc,
      TrainingTaskKind.exploration => task.module == TrainingModule.defense
          ? l10n.trainingTaskExploreDefenseDesc
          : l10n.trainingTaskExploreYakuDesc,
      TrainingTaskKind.weakSkill => _weaknessSubtitle(ref, l10n, task),
    };
  }

  String _weaknessSubtitle(
    WidgetRef ref,
    AppLocalizations l10n,
    TrainingPlanTask task,
  ) {
    final skillId = task.focusSkillId;
    if (skillId == null) return l10n.trainingTaskWeakDesc;
    if (task.module == TrainingModule.nanikiru) {
      final stats = ref.watch(nanikiruSkillMasteryProvider).skill(skillId);
      if (stats != null && stats.attempts > 0) {
        return l10n.trainingTaskWeakEvidence(stats.correct, stats.attempts);
      }
    }
    if (task.module == TrainingModule.defense) {
      final stats = ref.watch(defenseProgressProvider).skill(skillId);
      if (stats != null && stats.attempts > 0) {
        return l10n.trainingTaskWeakEvidence(stats.correct, stats.attempts);
      }
    }
    return l10n.trainingTaskWeakDesc;
  }

  String _skillLabel(AppLocalizations l10n, String? skillId) {
    return switch (skillId) {
      NanikiruSkillIds.isolatedTileHandling => l10n.trainingSkillIsolatedTiles,
      NanikiruSkillIds.taatsuOverload => l10n.trainingSkillTaatsuOverload,
      NanikiruSkillIds.pairProtection => l10n.trainingSkillPairProtection,
      NanikiruSkillIds.chiitoitsuCompetition =>
        l10n.trainingSkillChiitoitsuChoice,
      NanikiruSkillIds.kokushiTendency => l10n.trainingSkillKokushiShape,
      NanikiruSkillIds.generalTileEfficiency =>
        l10n.trainingSkillTileEfficiency,
      DefenseSkillIds.genbutsu => l10n.defenseTopicGenbutsu,
      DefenseSkillIds.suji => l10n.defenseTopicSuji,
      DefenseSkillIds.kabe => l10n.defenseTopicKabe,
      DefenseSkillIds.honorVisibility => l10n.defenseTopicHonorVisibility,
      DefenseSkillIds.combined => l10n.defenseTopicCombinedEvidence,
      _ => l10n.trainingSkillGeneral,
    };
  }

  String _routeFor(TrainingPlanTask task) {
    if (task.kind == TrainingTaskKind.dueReview ||
        task.module == TrainingModule.review) {
      return '/graveyard?source=today-plan&target=${task.remainingAttempts}';
    }
    if (task.kind == TrainingTaskKind.dailyChallenge) {
      return '/nanikiru?mode=daily&source=today-plan&target=${task.remainingAttempts}';
    }
    return switch (task.module) {
      TrainingModule.flashcard =>
        '/flashcard?source=today-plan&target=${task.remainingAttempts}',
      TrainingModule.nanikiru => task.focusSkillId == null
          ? '/nanikiru?source=today-plan&target=${task.remainingAttempts}'
          : '/nanikiru?source=today-plan&target=${task.remainingAttempts}&focusSkillId=${task.focusSkillId}',
      TrainingModule.defense => task.focusSkillId == null
          ? '/defense-training?source=today-plan&target=${task.remainingAttempts}'
          : '/defense-training?source=today-plan&target=${task.remainingAttempts}&focusSkillId=${task.focusSkillId}',
      TrainingModule.yaku =>
        '/yaku-quiz?source=today-plan&target=${task.remainingAttempts}',
      TrainingModule.review =>
        '/graveyard?source=today-plan&target=${task.remainingAttempts}',
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.jadeWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.jadeWhiteDim,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.complete,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String progressLabel;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final accent = complete
        ? const Color(0xFF2CE574)
        : active
            ? AppColors.neonGold
            : AppColors.jadeWhiteMuted;
    return Semantics(
      label: '$title, $subtitle',
      value: progressLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.neonGold.withOpacity(0.08)
              : AppColors.jadeDeep.withOpacity(0.36),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active
                ? AppColors.neonGold.withOpacity(0.32)
                : AppColors.jadeHover.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              complete ? Icons.check_circle_rounded : icon,
              color: accent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.jadeWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.jadeWhiteMuted,
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              progressLabel,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
