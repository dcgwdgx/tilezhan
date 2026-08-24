import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/utils/audio_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../training_plan/data/training_progress_persistence.dart';
import '../../training_plan/data/training_plan_store.dart';
import '../../training_plan/domain/training_plan.dart';
import '../data/defense_progress_store.dart';
import '../domain/defense_progress.dart';
import '../domain/defense_trainer.dart';
import '../domain/defense_training_state.dart';
import 'defense_training_screen.dart';

/// Product-level shell for a defense lesson.
///
/// The presentation-only screen owns the session state. This shell records one
/// SRS result and one aggregate skill result for every accepted answer, then
/// returns an exact-review completion result to the graveyard queue.
class DefenseTrainingPage extends ConsumerStatefulWidget {
  const DefenseTrainingPage({
    super.key,
    this.reviewQuestionId,
    this.focusSkillId,
    this.planTarget,
    this.seed,
  });

  final String? reviewQuestionId;
  final String? focusSkillId;
  final int? planTarget;
  final int? seed;

  @override
  ConsumerState<DefenseTrainingPage> createState() =>
      _DefenseTrainingPageState();
}

class _DefenseTrainingPageState extends ConsumerState<DefenseTrainingPage> {
  bool _hasUnflushedProgress = false;
  bool _savingProgress = false;
  void Function()? _pendingExactReviewSrsMutation;
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowPop || !_hasUnflushedProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(completed: false);
      },
      child: DefenseTrainingScreen(
        reviewQuestionId: widget.reviewQuestionId,
        focusTopic: _topicForSkillId(widget.focusSkillId),
        questionLimit:
            widget.reviewQuestionId == null ? widget.planTarget : null,
        seed: widget.seed,
        onAnswerRecorded: _recordAnswer,
        onCancel: () => _finish(completed: false),
        onDone: () => _finish(completed: true),
      ),
    );
  }

  void _recordAnswer(DefenseTrainingAnswer answer) {
    final isCorrect = answer.isCorrect;
    AnalyticsService.answered('defense_training', isCorrect);
    if (isCorrect) {
      AudioService.playCorrect();
    } else {
      AudioService.playWrong();
    }

    final question = answer.question;
    final skillId = _skillIdFor(question.topic);
    void recordSrs() {
      ref.read(srsNotifierProvider.notifier).recordReview(
            question.id,
            'defense',
            isCorrect ? 5 : 1,
            content: _buildSrsSnapshot(answer),
          );
    }

    if (widget.reviewQuestionId != null) {
      _pendingExactReviewSrsMutation = recordSrs;
    } else {
      recordSrs();
    }
    ref.read(defenseProgressProvider.notifier).recordAttempt(
          skillId: skillId,
          questionId: question.id,
          outcome: isCorrect
              ? DefenseAttemptOutcome.correct
              : DefenseAttemptOutcome.incorrect,
        );
    final occurredAt = DateTime.now();
    ref.read(dailyTrainingPlanProvider.notifier).recordAcceptedAttempt(
          TrainingAttemptEvent(
            eventId:
                'defense:${occurredAt.microsecondsSinceEpoch}:${question.id}',
            module: TrainingModule.defense,
            occurredAt: occurredAt.millisecondsSinceEpoch,
            isReview: widget.reviewQuestionId != null,
            skillIds: [skillId],
          ),
        );
    if (mounted) {
      setState(() => _hasUnflushedProgress = true);
    } else {
      _hasUnflushedProgress = true;
    }
  }

  Future<bool> _flushAcceptedProgress() async {
    if (!_hasUnflushedProgress) return true;
    if (_savingProgress) return false;

    _savingProgress = true;
    try {
      final pendingExactReview = _pendingExactReviewSrsMutation;
      if (pendingExactReview != null) {
        await ref.read(dailyTrainingPlanProvider.notifier).flush();
        pendingExactReview();
        _pendingExactReviewSrsMutation = null;
      }
      await ref.read(trainingProgressPersistenceProvider).flush(
            includeDefenseProgress: true,
          );
      _hasUnflushedProgress = false;
      return true;
    } on Object {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.trainingSaveError)));
      }
      return false;
    } finally {
      _savingProgress = false;
    }
  }

  Future<void> _finish({required bool completed}) async {
    if (!await _flushAcceptedProgress() || !mounted) return;
    _leaveScreen(
      completed && widget.reviewQuestionId != null ? true : null,
    );
  }

  void _leaveScreen([Object? result]) {
    if (!mounted) return;
    if (!context.canPop()) {
      context.go('/');
      return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(result);
      } else {
        context.go('/');
      }
    });
  }
}

/// Stable, language-neutral snapshot retained with the SRS item.
///
/// Published question IDs are append-only. The snapshot also preserves the
/// exact evidence used for the answer so future migrations remain auditable.
Map<String, dynamic> buildDefenseSrsSnapshot(DefenseTrainingAnswer answer) {
  return _buildSrsSnapshot(answer);
}

Map<String, dynamic> _buildSrsSnapshot(DefenseTrainingAnswer answer) {
  final question = answer.question;
  return {
    'schemaVersion': 1,
    'rulesetVersion': 'yonma_riichi_defense_v1',
    'questionId': question.id,
    'topic': question.topic.name,
    'targetSeat': question.targetSeat.name,
    'discardsBySeat': {
      for (final entry in question.discardsBySeat.entries)
        entry.key.name: List<String>.of(entry.value),
    },
    'additionalPublicVisibleCounts':
        Map<String, int>.of(question.additionalPublicVisibleCounts),
    'choices': [
      for (final choice in question.choices)
        {
          'id': choice.id,
          'tileId': choice.tileId,
          'riskLabel': choice.riskLabel.name,
          'evidenceTags': [
            for (final tag in choice.evidenceTags) tag.name,
          ],
          'explanationCode': choice.explanationCode.name,
        },
    ],
    'bestChoiceId': question.bestChoiceId,
    'lastSelectedChoiceId': answer.selectedChoice.id,
    'lastOutcome': answer.isCorrect ? 'correct' : 'incorrect',
  };
}

String _skillIdFor(DefenseTopic topic) => switch (topic) {
      DefenseTopic.genbutsu => DefenseSkillIds.genbutsu,
      DefenseTopic.suji => DefenseSkillIds.suji,
      DefenseTopic.kabe => DefenseSkillIds.kabe,
      DefenseTopic.honorVisibility => DefenseSkillIds.honorVisibility,
      DefenseTopic.combinedEvidence => DefenseSkillIds.combined,
    };

DefenseTopic? _topicForSkillId(String? skillId) => switch (skillId) {
      DefenseSkillIds.genbutsu => DefenseTopic.genbutsu,
      DefenseSkillIds.suji => DefenseTopic.suji,
      DefenseSkillIds.kabe => DefenseTopic.kabe,
      DefenseSkillIds.honorVisibility => DefenseTopic.honorVisibility,
      DefenseSkillIds.combined => DefenseTopic.combinedEvidence,
      _ => null,
    };
