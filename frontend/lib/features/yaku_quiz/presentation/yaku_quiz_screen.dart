import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/utils/audio_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tz_battle_report.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../yaku_detail/domain/yaku_data.dart';
import '../../training_plan/data/training_progress_persistence.dart';
import '../../training_plan/data/training_plan_store.dart';
import '../../training_plan/domain/training_plan.dart';
import '../domain/yaku_quiz_provider.dart';
import '../domain/yaku_quiz_question.dart';
import '../domain/yaku_quiz_state.dart';
import 'yaku_quiz_copy.dart';

/// 役种知识训练：定义识别、门清/副露番数和规则判断。
class YakuQuizScreen extends ConsumerStatefulWidget {
  final String? reviewQuestionId;
  final int? seed;
  final int? planTarget;
  final bool requirePlanProgressForTarget;

  const YakuQuizScreen({
    super.key,
    this.reviewQuestionId,
    this.seed,
    this.planTarget,
    this.requirePlanProgressForTarget = false,
  });

  @override
  ConsumerState<YakuQuizScreen> createState() => _YakuQuizScreenState();
}

class _YakuQuizScreenState extends ConsumerState<YakuQuizScreen> {
  bool _started = false;
  bool _gameOver = false;
  late final String _trainingSessionId;
  late final String _trainingSessionDateKey;
  int _trainingEventIndex = 0;
  int _trainingAttempts = 0;
  bool _planContextChanged = false;
  bool _hasUnflushedProgress = false;
  bool _savingProgress = false;
  void Function()? _pendingExactReviewSrsMutation;
  bool _allowPop = false;

  bool get _isReview => widget.reviewQuestionId != null;
  bool get _planTargetReached =>
      _planContextChanged ||
      (widget.planTarget != null && _trainingAttempts >= widget.planTarget!);

  @override
  void initState() {
    super.initState();
    _trainingSessionId = DateTime.now().microsecondsSinceEpoch.toString();
    _trainingSessionDateKey = trainingDateKey(DateTime.now());
    Future.microtask(() {
      if (!mounted) return;
      if (!_isReview && !ref.read(canPlayProvider)) {
        _showBattleReport();
        return;
      }
      try {
        ref.read(yakuQuizProvider.notifier).start(
              seed: widget.seed ?? DateTime.now().millisecondsSinceEpoch,
              reviewQuestionId: widget.reviewQuestionId,
            );
        if (mounted) setState(() => _started = true);
      } on ArgumentError {
        if (!mounted) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    });
  }

  void _submit(YakuQuizAnswer answer) {
    final before = ref.read(yakuQuizProvider);
    final question = before.currentQuestion;
    if (question == null) return;

    final result = ref.read(yakuQuizProvider.notifier).submit(answer);
    if (!result.wasRecorded) return;

    AnalyticsService.answered('yaku_quiz', result.isCorrect);
    if (result.isCorrect) {
      AudioService.playCorrect();
    } else {
      AudioService.playWrong();
    }

    void recordSrs() {
      ref.read(srsNotifierProvider.notifier).recordReview(
        question.id,
        'yaku',
        result.isCorrect ? 5 : 1,
        content: {
          'questionId': question.id,
          'questionKind': question.kind.name,
          'correctAnswer': _answerStorageValue(question.correctAnswer),
        },
      );
    }

    if (_isReview) {
      // Exact reviews commit their plan event first. If the process stops at
      // either side of the two stores, the due item may safely reappear, but
      // the fixed daily review task can never become impossible to finish.
      _pendingExactReviewSrsMutation = recordSrs;
    } else {
      recordSrs();
    }
    final now = DateTime.now();
    final occurredAt = now.millisecondsSinceEpoch;
    if (widget.requirePlanProgressForTarget &&
        trainingDateKey(now) != _trainingSessionDateKey) {
      _planContextChanged = true;
    }
    final planAdvanced =
        ref.read(dailyTrainingPlanProvider.notifier).recordAcceptedAttempt(
              TrainingAttemptEvent(
                eventId:
                    'yaku:$_trainingSessionId:${_trainingEventIndex++}:${question.id}',
                module: TrainingModule.yaku,
                occurredAt: occurredAt,
                isReview: _isReview,
              ),
            );
    if (!widget.requirePlanProgressForTarget || planAdvanced) {
      _trainingAttempts += 1;
    }
    _hasUnflushedProgress = true;

    final hearts = ref.read(heartServiceProvider);
    if (result.isCorrect) {
      hearts.recordCorrect();
    } else {
      hearts.recordWrong();
      if (!_isReview && ref.read(trainingAccessProvider).shouldConsumeHearts) {
        _gameOver = hearts.consume();
      }
    }
    if (mounted) setState(() {});
  }

  Object _answerStorageValue(YakuQuizAnswer answer) => switch (answer.kind) {
        YakuQuizAnswerKind.yakuId => answer.yakuId!,
        YakuQuizAnswerKind.han => answer.han!,
        YakuQuizAnswerKind.boolean => answer.booleanValue!,
      };

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
      await ref.read(trainingProgressPersistenceProvider).flush();
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

  Future<void> _closeScreen() async {
    if (!await _flushAcceptedProgress() || !mounted) return;
    _leaveScreen();
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

  Widget _withProgressPopGuard(Widget child) {
    return PopScope<Object?>(
      canPop: _allowPop || !_hasUnflushedProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeScreen();
      },
      child: child,
    );
  }

  Future<void> _next() async {
    if (!await _flushAcceptedProgress() || !mounted) return;
    if (_gameOver) {
      _showBattleReport();
      return;
    }
    if (_planTargetReached) {
      AudioService.playComplete();
      _leaveScreen();
      return;
    }
    final advanced = ref.read(yakuQuizProvider.notifier).next();
    if (!advanced) return;
    if (_isReview) {
      _leaveScreen(true);
      return;
    }
    if (ref.read(yakuQuizProvider).phase == YakuQuizPhase.completed) {
      AudioService.playComplete();
    }
  }

  void _restart() {
    _gameOver = false;
    ref.read(yakuQuizProvider.notifier).start(
          seed: DateTime.now().millisecondsSinceEpoch,
        );
    setState(() {});
  }

  void _showBattleReport() {
    if (!ref.read(trainingAccessProvider).shouldConsumeHearts) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TzBattleReport(),
    ).then((_) {
      if (!mounted) return;
      _leaveScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(yakuQuizProvider);
    if (!_started) {
      return _withProgressPopGuard(const Scaffold(
        backgroundColor: AppColors.jadeDeep,
        body: Center(child: CircularProgressIndicator()),
      ));
    }
    if (state.phase == YakuQuizPhase.completed) {
      return _withProgressPopGuard(_buildSummary(l10n, state));
    }

    final question = state.currentQuestion!;
    final progress = state.totalCount == 0
        ? 0.0
        : (state.currentIndex + 1) / state.totalCount;
    return _withProgressPopGuard(Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.jadeWhiteDim),
          onPressed: _closeScreen,
        ),
        title: Text(
          l10n.yakuQuizTitle,
          style: const TextStyle(
            color: AppColors.jadeWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l10n.yakuQuizProgress(
                  state.currentIndex + 1,
                  state.totalCount,
                ),
                style: const TextStyle(color: AppColors.neonGold),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TzProgressBar(value: progress, height: 5),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(
              question.promptKey.localize(l10n),
              style: const TextStyle(
                color: AppColors.jadeWhite,
                fontSize: 22,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            ...question.options.map(
              (answer) => _buildAnswer(
                l10n,
                state,
                question,
                answer,
              ),
            ),
            if (state.phase == YakuQuizPhase.revealed) ...[
              const SizedBox(height: 12),
              _buildExplanation(l10n, state, question),
              const SizedBox(height: 20),
              TzButton(
                label: _isReview
                    ? l10n.yakuQuizReviewDone
                    : state.currentIndex + 1 >= state.totalCount
                        ? l10n.yakuQuizFinish
                        : l10n.yakuQuizNext,
                style: TzButtonStyle.gold,
                icon: Icons.arrow_forward,
                onPressed: _next,
              ),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _buildAnswer(
    AppLocalizations l10n,
    YakuQuizState state,
    YakuQuizQuestion question,
    YakuQuizAnswer answer,
  ) {
    final revealed = state.phase == YakuQuizPhase.revealed;
    final isCorrect = answer == question.correctAnswer;
    final wasSelected = answer == state.selectedAnswer;
    final color = revealed && isCorrect
        ? const Color(0xFF2CE574)
        : revealed && wasSelected
            ? AppColors.vermillion
            : AppColors.jadeHover;
    final background = revealed && (isCorrect || wasSelected)
        ? color.withOpacity(0.14)
        : AppColors.jadeCard;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: revealed ? null : () => _submit(answer),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _answerLabel(l10n, answer),
                  style: const TextStyle(
                    color: AppColors.jadeWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (revealed && isCorrect)
                const Icon(Icons.check_circle, color: Color(0xFF2CE574))
              else if (revealed && wasSelected)
                const Icon(Icons.cancel, color: AppColors.vermillion),
            ],
          ),
        ),
      ),
    );
  }

  String _answerLabel(AppLocalizations l10n, YakuQuizAnswer answer) {
    return switch (answer.kind) {
      YakuQuizAnswerKind.yakuId =>
        getYakuById(answer.yakuId!)?.nameEn.split(' (').first ?? answer.yakuId!,
      YakuQuizAnswerKind.han => l10n.yakuQuizHanOption(answer.han!),
      YakuQuizAnswerKind.boolean =>
        answer.booleanValue! ? l10n.yakuQuizTrue : l10n.yakuQuizFalse,
    };
  }

  Widget _buildExplanation(
    AppLocalizations l10n,
    YakuQuizState state,
    YakuQuizQuestion question,
  ) {
    final correct = state.lastAnswerWasCorrect ?? false;
    final color = correct ? const Color(0xFF2CE574) : AppColors.vermillion;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? l10n.yakuQuizCorrect : l10n.yakuQuizIncorrect,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.yakuQuizExplanation,
            style: const TextStyle(
              color: AppColors.neonGold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            question.explanationKey.localize(l10n),
            style: const TextStyle(
              color: AppColors.jadeWhiteDim,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(AppLocalizations l10n, YakuQuizState state) {
    final accuracy = (state.accuracy * 100).round();
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.jadeWhiteDim),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎓', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                l10n.yakuQuizSummaryTitle,
                style: const TextStyle(
                  color: AppColors.jadeWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.yakuQuizSummaryBody(
                  state.correctCount,
                  state.totalCount,
                  accuracy,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.jadeWhiteDim,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              TzButton(
                label: l10n.yakuQuizTryAgain,
                style: TzButtonStyle.gold,
                icon: Icons.refresh,
                onPressed: _restart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
