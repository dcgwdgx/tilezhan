/// 何切（牌效率选择）屏幕 — ELO 难度匹配 + 斜切动画。
///
/// 手牌展示 + 倒计时条 + 切牌确认/跳过 + 统一结算逻辑。
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/elo/elo_provider.dart';
import '../../../core/providers/player_name_provider.dart';
import '../../../core/utils/audio_service.dart';
import '../../../core/utils/review_service.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../shared/widgets/tz_battle_report.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../../shared/widgets/tz_slash_painter.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../leaderboard/domain/leaderboard_service.dart';
import '../../training_plan/data/training_progress_persistence.dart';
import '../../training_plan/data/training_plan_store.dart';
import '../../training_plan/domain/training_plan.dart';
import '../domain/nanikiru_provider.dart';
import '../domain/nanikiru_skill_mastery.dart';
import '../domain/nanikiru_skill_mastery_provider.dart';
import '../domain/nanikiru_snapshot.dart';
import '../domain/nanikiru_state.dart';
import 'nanikiru_feedback_panel.dart';

/// 何切牌效率选择屏幕——Riverpod ConsumerStatefulWidget 顶层入口。
///
/// 核心玩法：从14张手牌中选出最优切牌，系统根据有效牌接受数（ukeire）判定对错。
/// 练习模式下答对不消耗体力，答错、跳过或超时才消耗；会员和复习模式不限体力。
/// 所有结果只经过一次统一结算，并写入可精准重放的 SRS 内容快照。
enum NanikiruMode { practice, dailyChallenge, review }

class NanikiruScreen extends ConsumerStatefulWidget {
  final NanikiruMode mode;
  final String? reviewItemId;
  final String? focusSkillId;
  final int? planTarget;
  final bool requirePlanProgressForTarget;

  const NanikiruScreen({
    super.key,
    this.mode = NanikiruMode.practice,
    this.reviewItemId,
    this.focusSkillId,
    this.planTarget,
    this.requirePlanProgressForTarget = false,
  });

  // 创建与该 Widget 绑定的状态对象——Flutter 框架在 inflate 时调用
  @override
  ConsumerState<NanikiruScreen> createState() => _NanikiruScreenState();
}

// 何切屏幕的界面状态管理类。
// 混入 TickerProviderStateMixin，为斩击和反馈面板两个动画提供 vsync 信号。
// 职责：倒计时定时器、斜切动画、对局计数、游戏结束判定、所有子组件构建。
class _NanikiruScreenState extends ConsumerState<NanikiruScreen>
    with TickerProviderStateMixin {
  Timer? _timer; // 50ms 周期倒计时定时器——每 tick 调用 tickCountdown(0.05) 递减 0.05 秒
  late AnimationController
      _slashCtrl; // 切牌确认后的斜切动画控制器（1000ms 时长，由 TzSlashPainter 消费）
  late AnimationController _panelCtrl; // 复盘面板滑入动画控制器（350ms，easeOutCubic 减速收尾）
  late Animation<Offset> _panelSlide; // 面板从底部滑入的位移动画（Offset(0,1)→Offset.zero）
  int _sessionCount = 0; // 本次会话已对局计数，驱动导航栏 ⚔️N 显示
  bool _gameOver = false; // 心耗尽封锁后续答题
  int _dailyAttempted = 0;
  int _dailyCorrect = 0;
  late final String _trainingSessionId;
  late final String _trainingSessionDateKey;
  int _trainingEventIndex = 0;
  int _trainingAttempts = 0;
  bool _planContextChanged = false;
  Future<void> _settlementBarrier = Future<void>.value();
  bool _hasUnflushedProgress = false;
  bool _savingProgress = false;
  bool _unrecoverableReviewSaveFailed = false;
  void Function()? _pendingExactReviewSrsMutation;
  String? _unrecoverableReviewItemId;
  bool _unrecoverableSrsDiscardApplied = false;
  bool _savingUnrecoverableReview = false;
  bool _allowPop = false;

  bool get _isDaily => widget.mode == NanikiruMode.dailyChallenge;
  bool get _isReview => widget.mode == NanikiruMode.review;
  String? get _reviewItemId {
    final normalized = widget.reviewItemId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  int get _dailyTarget => widget.planTarget ?? 3;
  bool get _dailyCompleted =>
      _isDaily && !_planContextChanged && _trainingAttempts >= _dailyTarget;
  bool get _planTargetReached =>
      _planContextChanged ||
      (widget.planTarget != null && _trainingAttempts >= widget.planTarget!);

  // 初始化斜切动画控制器和面板滑入动画控制器，随后在微任务中检查玩家状态：
  // - 心耗尽/每日挑战用尽 → 弹出 TzBattleReport 战报
  // - 正常状态 → 初始化谜题并启动倒计时
  @override
  void initState() {
    super.initState();
    _trainingSessionId = DateTime.now().microsecondsSinceEpoch.toString();
    _trainingSessionDateKey = trainingDateKey(DateTime.now());
    _slashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _panelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _panelSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));
    Future.microtask(() async {
      if (!mounted) return;
      final reviewItemId = _reviewItemId;
      if (_isReview && reviewItemId == null) {
        // GoRouter redirects malformed review links before constructing this
        // screen. Keep the widget itself defensive for tests and future direct
        // call sites: never turn a missing due-review ID into a random puzzle.
        _leaveScreen();
        return;
      }
      if (!_isDaily && !_isReview && !ref.read(canPlayProvider)) {
        _maybeShowBattleReport();
        return;
      }
      try {
        await ref.read(nanikiruProvider.notifier).initPuzzle(
              reviewItemId: reviewItemId,
              preferredSkillId: widget.focusSkillId,
            );
      } on ArgumentError {
        if (!mounted) return;
        if (_isReview && reviewItemId != null) {
          setState(() => _unrecoverableReviewItemId = reviewItemId);
          final occurredAt = DateTime.now().millisecondsSinceEpoch;
          ref.read(dailyTrainingPlanProvider.notifier).recordAcceptedAttempt(
                TrainingAttemptEvent(
                  eventId:
                      'nanikiru-unrecoverable:$_trainingSessionId:$reviewItemId',
                  module: TrainingModule.nanikiru,
                  occurredAt: occurredAt,
                  isReview: true,
                ),
              );
          await _finishUnrecoverableReview();
          return;
        }
        if (context.canPop()) {
          // An obsolete ambiguous SRS snapshot is intentionally treated as a
          // completed skip so a mixed "Review All" queue can continue.
          context.pop(_isReview ? true : null);
        } else {
          context.go('/');
        }
        return;
      }
      if (mounted) _startCountdown();
    });
  }

  // 清理定时器和动画控制器，防止内存泄漏和回调在 dispose 后触发
  @override
  void dispose() {
    _timer?.cancel();
    _slashCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  /// Start a 50 ms periodic timer that ticks the countdown by 0.05 s per frame.
  /// Cancels automatically when the puzzle is finished.
  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final notifier = ref.read(nanikiruProvider.notifier);
      final state = ref.read(nanikiruProvider);
      if (state.isFinished) {
        _timer?.cancel();
        return;
      }
      notifier.tickCountdown(0.05);
    });
  }

  /// Show the battle report or a 10-win streak promo when hearts are depleted.
  /// Closes back to the home screen after dismissal.
  void _maybeShowBattleReport() {
    if (!ref.read(trainingAccessProvider).shouldConsumeHearts) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TzBattleReport(),
    ).then((_) {
      if (!mounted) return;
      _leaveScreen();
    });
  }

  /// Tracks the isFinished rising edge so side effects (analytics, hearts, SRS)
  /// fire exactly once per puzzle when the player confirms a discard.
  bool _wasFinished = false;

  Future<bool> _flushAcceptedProgress() async {
    await _settlementBarrier;
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
            includeNanikiruMastery: true,
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
    final hasUnrecoverableCommit = _unrecoverableReviewItemId != null;
    return PopScope<Object?>(
      canPop: _allowPop || (!_hasUnflushedProgress && !hasUnrecoverableCommit),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (hasUnrecoverableCommit) {
          _finishUnrecoverableReview();
        } else {
          _closeScreen();
        }
      },
      child: child,
    );
  }

  Future<void> _finishUnrecoverableReview() async {
    if (_savingUnrecoverableReview) return;
    _savingUnrecoverableReview = true;
    try {
      await ref.read(dailyTrainingPlanProvider.notifier).flush();
      if (!_unrecoverableSrsDiscardApplied) {
        ref
            .read(srsNotifierProvider.notifier)
            .discardUnrecoverableItem(_unrecoverableReviewItemId!);
        _unrecoverableSrsDiscardApplied = true;
      }
      await ref.read(srsNotifierProvider.notifier).flush();
    } on Object {
      if (!mounted) return;
      setState(() => _unrecoverableReviewSaveFailed = true);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.trainingSaveError)));
      return;
    } finally {
      _savingUnrecoverableReview = false;
    }
    if (!mounted) return;
    _unrecoverableReviewItemId = null;
    _leaveScreen(true);
  }

  void _settleResult(NaniKiruState state) {
    final hasCommittedDiscard = state.outcome == NaniKiruOutcome.perfect ||
        state.outcome == NaniKiruOutcome.incorrect;
    if (hasCommittedDiscard) {
      AudioService.playSlash();
      _slashCtrl.forward(from: 0);
    } else {
      _slashCtrl.value = 0;
    }
    AnalyticsService.answered('nanikiru', state.isPerfect);

    final hearts = ref.read(heartServiceProvider);
    if (state.isPerfect) {
      hearts.recordCorrect();
    } else {
      hearts.recordWrong();
    }

    final handIds = state.handTiles.map((tile) => tile.id).toList();
    final drawnIndex = handIds.lastIndexOf(state.drawnTileId);
    if (drawnIndex >= 0) handIds.removeAt(drawnIndex);
    final skillIds = state.teachingAnalysis?.optimalTags
            .map((tag) => tag.skillId)
            .toSet()
            .toList() ??
        <String>[];
    skillIds.sort();
    if (skillIds.isNotEmpty) {
      ref.read(nanikiruSkillMasteryProvider.notifier).recordAttempt(
            skillIds: skillIds,
            outcome: state.outcome,
            puzzleDifficulty: state.difficulty,
          );
    }
    final quality = switch (state.outcome) {
      NaniKiruOutcome.perfect => 5,
      NaniKiruOutcome.skipped => 2,
      NaniKiruOutcome.timedOut => 0,
      _ => 1,
    };
    final reviewItemId = _reviewItemId;
    if (_isReview && reviewItemId == null) return;
    final persistedPuzzleId = reviewItemId ?? state.puzzleId;
    void recordSrs() {
      ref.read(srsNotifierProvider.notifier).recordReview(
            persistedPuzzleId,
            'nanikiru',
            quality,
            content: buildNanikiruSnapshotContent(
              puzzleId: persistedPuzzleId,
              hand13Ids: handIds,
              drawnTileId: state.drawnTileId,
              correctDiscardId: state.correctDiscardId,
              ukeireCount: state.ukeireCount ?? 0,
              ukeireTypes: state.ukeireTypes ?? 0,
              ukeireTileIds: state.ukeireTiles ?? const <String>[],
              difficulty: state.difficulty,
              metadata: {
                'lastSelectedTileId': state.selectedTileId,
                'lastOutcome': state.outcome.name,
                'skillTaxonomyVersion':
                    NanikiruSkillMasteryProfile.taxonomyVersion,
                'skillTags': skillIds,
              },
            ),
          );
    }

    if (_isReview) {
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
                    'nanikiru:$_trainingSessionId:${_trainingEventIndex++}:$persistedPuzzleId',
                module: TrainingModule.nanikiru,
                occurredAt: occurredAt,
                isReview: _isReview,
                isDailyChallenge: _isDaily,
                skillIds: skillIds,
              ),
            );
    if (!widget.requirePlanProgressForTarget || planAdvanced) {
      _trainingAttempts += 1;
    }

    if (_isDaily) {
      _dailyAttempted += 1;
      if (state.isPerfect) _dailyCorrect += 1;
      if (mounted) setState(() {});
      return;
    }

    if (_isReview) return;

    ref.read(eloProvider.notifier).recordResult(
          isCorrect: state.isPerfect,
          isSkip: state.isSkipped,
        );

    if (state.isPerfect) {
      try {
        final prefs = Hive.box('prefs');
        final lastReview = prefs.get(kLastReviewKey, defaultValue: '');
        maybeRequestReview(hearts.allTimeCombo, lastReview);
        prefs.put(
            kLastReviewKey, DateTime.now().toIso8601String().substring(0, 10));
      } catch (_) {}
    } else if (ref.read(trainingAccessProvider).shouldConsumeHearts) {
      _gameOver = hearts.consume();
    }

    final name = ref.read(playerNameProvider);
    if (name.isNotEmpty) {
      LeaderboardService.reportScore(
        name: name,
        elo: ref.read(eloProvider),
        streak: hearts.allTimeCombo,
      );
    }
  }

  Future<void> _showDailySummary() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final accuracy = _dailyAttempted == 0
        ? 0
        : ((_dailyCorrect / _dailyAttempted) * 100).round();
    final learningStreak =
        ref.read(dailyTrainingPlanProvider)?.currentStreak ?? 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.jadeCard,
        title: Text(l10n.dailySummaryTitle,
            style: const TextStyle(color: AppColors.neonGold)),
        content: Text(
          l10n.dailySummaryBody(
            _dailyCorrect,
            _dailyAttempted,
            accuracy,
            learningStreak,
          ),
          style: const TextStyle(color: AppColors.jadeWhiteDim, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.dailySummaryDone),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _leaveScreen();
  }

  // 主构建方法：监听 nanikiruProvider 状态变化，协调三个关键流程：
  // 1. 答题确认副作用（isFinished 上升沿检测）：播放音效/动画/埋点/扣心/SRS记录
  // 2. 空手牌守卫：数据未加载时显示加载指示器
  // 3. 主游戏布局：导航栏 → 摸牌提示 → 倒计时条 → 手牌区 → 工具栏 → 反馈浮层
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(nanikiruProvider);
    final notifier = ref.read(nanikiruProvider.notifier);

    if (_unrecoverableReviewSaveFailed) {
      return _withProgressPopGuard(Scaffold(
        backgroundColor: AppColors.jadeDeep,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.trainingSaveError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.jadeWhiteDim,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TzButton(
                    key: const ValueKey('nanikiru-retry-review-save'),
                    label: l10n.trainingSaveRetry,
                    icon: Icons.refresh_rounded,
                    style: TzButtonStyle.gold,
                    onPressed: () {
                      setState(() => _unrecoverableReviewSaveFailed = false);
                      _finishUnrecoverableReview();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }

    // --- Side effects on answer confirmation ---
    if (state.isFinished && !_wasFinished) {
      _wasFinished = true;
      _hasUnflushedProgress = true;
      _panelCtrl.forward(from: 0); // 面板从底部滑入
      final settlement = Completer<void>();
      _settlementBarrier = settlement.future;
      Future.microtask(() {
        try {
          _settleResult(ref.read(nanikiruProvider));
        } finally {
          settlement.complete();
        }
      });
    }
    // 谜题未完成时重置 _wasFinished 标记，为下一题的上升沿检测做准备
    if (!state.isFinished) {
      _wasFinished = false;
    }

    // --- Empty / loading guard ---
    if (state.handTiles.isEmpty) {
      return _withProgressPopGuard(const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ));
    }

    // --- Main game layout: nav → prompt → countdown → hand → toolbar ---
    return _withProgressPopGuard(Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildNavBar(),
                const SizedBox(height: 8),
                _buildPrompt(state),
                const SizedBox(height: 12),
                _buildCountdownBar(state),
                const SizedBox(height: 12),
                _buildHandArea(state, notifier),
                const SizedBox(height: 12),
                _buildToolbar(state, notifier),
              ],
            ),
            // --- Post-answer slash animation overlay ---
            if (state.isFinished) ...[
              if (state.outcome == NaniKiruOutcome.perfect ||
                  state.outcome == NaniKiruOutcome.incorrect)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: TzSlashPainter(
                        progress: _slashCtrl.value,
                        color: state.isPerfect
                            ? AppColors.neonGold
                            : AppColors.vermillion,
                      ),
                    ),
                  ),
                ),
              if (state.isPerfect)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: TzParticlePainter(progress: _slashCtrl.value),
                    ),
                  ),
                ),
              Positioned.fill(
                child: NanikiruFeedbackPanel(
                  state: state,
                  panelSlide: _panelSlide,
                  onNextPuzzle: () async {
                    if (!await _flushAcceptedProgress() || !mounted) return;
                    await _panelCtrl.reverse();
                    if (!mounted) return;
                    if (_dailyCompleted) {
                      _showDailySummary();
                      return;
                    }
                    if (_isReview) {
                      _leaveScreen(true);
                      return;
                    }
                    if (_planTargetReached) {
                      AudioService.playComplete();
                      _leaveScreen();
                      return;
                    }
                    if (_gameOver ||
                        (!_isDaily && !ref.read(canPlayProvider))) {
                      _gameOver = true;
                      _maybeShowBattleReport();
                      return;
                    }
                    _sessionCount++;
                    await notifier.nextPuzzle();
                    if (mounted) _startCountdown();
                  },
                  nextButtonLabel: _dailyCompleted
                      ? l10n.dailyViewResult
                      : _isReview
                          ? l10n.reviewFinish
                          : null,
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  /// Top navigation bar: back button, title, and session counter.
  Widget _buildNavBar() {
    final l10n = AppLocalizations.of(context)!;
    final dailyStep = ref.read(nanikiruProvider).isFinished
        ? _dailyAttempted
        : (_dailyAttempted + 1).clamp(1, _dailyTarget).toInt();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
            onPressed: _closeScreen,
          ),
          Expanded(
            child: Text(l10n.nanikiruNavTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.jadeWhite,
                )),
          ),
          Text(
              _isDaily
                  ? l10n.dailyProgress(
                      dailyStep,
                      _dailyTarget,
                    )
                  : l10n.nanikiruSessionCount('${_sessionCount + 1}'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.neonGold,
              )),
        ],
      ),
    );
  }

  /// Drawn-tile card showing the tile the player just picked up.
  Widget _buildPrompt(NaniKiruState state) {
    final l10n = AppLocalizations.of(context)!;
    // 从牌库查询当前摸到的牌数据（用于渲染牌面文字和新牌标签）
    final drawnTile =
        ref.read(tileRepositoryProvider).getById(state.drawnTileId, []);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.jadeCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neonGold.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(l10n.nanikiruDraw,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.jadeWhiteDim,
                )),
            const SizedBox(height: 6),
            if (drawnTile != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neonGold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.neonGold.withOpacity(0.3),
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(drawnTile.character,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.jadeWhite,
                          fontFamily: 'Noto Serif SC',
                        )),
                    const SizedBox(width: 6),
                    Text('${drawnTile.label} ← ${l10n.nanikiruNew}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonGold,
                        )),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(l10n.nanikiruDiscardHint,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.neonGold.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Text(
              l10n.nanikiruEfficiencyScope,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: AppColors.jadeWhiteDim.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Countdown progress bar. Turns red and urgent below 3 seconds.
  Widget _buildCountdownBar(NaniKiruState state) {
    final l10n = AppLocalizations.of(context)!;
    final progress = state.countdownValue / 10.0;
    final isUrgent = state.countdownValue <= 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.nanikiruDecision,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.jadeWhiteMuted,
                  )),
              Text(state.countdownValue.toStringAsFixed(1) + 's',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isUrgent ? AppColors.vermillion : AppColors.neonGold,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          TzProgressBar(
            value: progress,
            color: isUrgent ? AppColors.vermillion : AppColors.neonGold,
            height: 6,
          ),
        ],
      ),
    );
  }

  /// 14-tile hand display with tappable TzTile widgets.
  /// Selected tile is highlighted; tapping a tile toggles selection.
  Widget _buildHandArea(NaniKiruState state, NanikiruNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Text(l10n.nanikiruHandLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.jadeWhiteMuted,
                )),
            const SizedBox(height: 10),
            Expanded(
              child: Wrap(
                spacing: 5, runSpacing: 5,
                alignment: WrapAlignment.center,
                // 将手牌列表转为带索引的 Map，根据选中状态渲染 TzTile（选中 ⇄ 高亮）
                children: state.handTiles.asMap().entries.map((entry) {
                  final tile = entry.value;
                  final isSelected = state.selectedTileId == tile.id;

                  return TzTile(
                    tile: tile,
                    size: TileSize.md,
                    state: isSelected ? TileState.selected : TileState.normal,
                    onTap: () => notifier.onTileTapped(tile.id),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom toolbar: Sort, Hint, and Skip buttons. Hidden after answer.
  Widget _buildToolbar(NaniKiruState state, NanikiruNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isFinished) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toolBtn(l10n.nanikiruSort, () => notifier.sortHand()),
          const SizedBox(width: 8),
          _toolBtn(l10n.nanikiruHintTitle, () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.jadeCard,
                title: Text(l10n.nanikiruHintTitle,
                    style: const TextStyle(color: AppColors.neonGold)),
                content: Text(l10n.nanikiruHint,
                    style: const TextStyle(color: AppColors.jadeWhiteDim)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.nanikiruGotIt,
                          style: const TextStyle(color: AppColors.neonGold)))
                ],
              ),
            );
          }),
          const SizedBox(width: 8),
          _toolBtn(l10n.nanikiruSkip, () {
            notifier.confirmDiscard('', isSkip: true);
          }),
        ],
      ),
    );
  }

  /// Styled pill button with an outlined border.
  Widget _toolBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.jadeHover),
        ),
        child: Text(text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.jadeWhiteDim,
            )),
      ),
    );
  }

  /// Full-width feedback panel shown after answering.
}
