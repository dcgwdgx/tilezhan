/// 何切（牌效率选择）屏幕 — ELO 难度匹配 + 斜切动画。
///
/// 手牌展示 + 倒计时条 + 切牌确认/跳过 + 计费逻辑。
/// 正确 = 更新战绩 + 扣心；错误 = 进错题池不扣心。

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
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../shared/widgets/tz_battle_report.dart';
import '../../../shared/widgets/tz_combo_promo.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../../shared/widgets/tz_slash_painter.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../leaderboard/domain/leaderboard_service.dart';
import '../domain/nanikiru_provider.dart';
import '../domain/nanikiru_state.dart';
import 'nanikiru_feedback_panel.dart';

/// 何切牌效率选择屏幕——Riverpod ConsumerStatefulWidget 顶层入口。
///
/// 核心玩法：从14张手牌中选出最优切牌，系统根据有效牌接受数（ukeire）判定对错。
/// 正确：更新战绩连击 + 扣心 + SRS间隔复习记录（质量=5）。
/// 错误：入错题池免费重试，不扣心（质量=1）；跳过也计为一次尝试（质量=2）。
class NanikiruScreen extends ConsumerStatefulWidget {
  const NanikiruScreen({super.key});

  // 创建与该 Widget 绑定的状态对象——Flutter 框架在 inflate 时调用
  @override
  ConsumerState<NanikiruScreen> createState() => _NanikiruScreenState();
}

// 何切屏幕的界面状态管理类。
// 混入 SingleTickerProviderStateMixin 为 TzSlashPainter 斜切动画提供 vsync 信号。
// 职责：倒计时定时器、斜切动画、对局计数、游戏结束判定、所有子组件构建。
class _NanikiruScreenState extends ConsumerState<NanikiruScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer; // 50ms 周期倒计时定时器——每 tick 调用 tickCountdown(0.05) 递减 0.05 秒
  late AnimationController _slashCtrl; // 切牌确认后的斜切动画控制器（1000ms 时长，由 TzSlashPainter 消费）
  late AnimationController _panelCtrl; // 复盘面板滑入动画控制器（350ms，easeOutCubic 减速收尾）
  late Animation<Offset> _panelSlide; // 面板从底部滑入的位移动画（Offset(0,1)→Offset.zero）
  int _sessionCount = 0; // 本次会话已对局计数，驱动导航栏 ⚔️N 显示
  bool _gameOver = false; // 心耗尽封锁后续答题

  // 初始化斜切动画控制器和面板滑入动画控制器，随后在微任务中检查玩家状态：
  // - 心耗尽/每日挑战用尽 → 弹出 TzBattleReport 战报
  // - 正常状态 → 初始化谜题并启动倒计时
  @override
  void initState() {
    super.initState();
    _slashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _panelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _panelSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic));
    Future.microtask(() {
      // Show battle report if the player is out of hearts / daily challenges
      if (!ref.read(canPlayProvider)) {
        _maybeShowBattleReport();
        return;
      }
      ref.read(nanikiruProvider.notifier).initPuzzle();
      _startCountdown();
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
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TzBattleReport(),
    ).then((_) {
      if (mounted) context.pop();
    });
  }

  /// Tracks the isFinished rising edge so side effects (analytics, hearts, SRS)
  /// fire exactly once per puzzle when the player confirms a discard.
  bool _wasFinished = false;

  /// Record a spaced-repetition review for the current puzzle.
  /// Quality: 5 = perfect, 2 = skip, 1 = wrong answer.
  void _recordSrs(bool isSkip) {
    final state = ref.read(nanikiruProvider);
    final quality = state.isPerfect ? 5 : (isSkip ? 2 : 1);
    ref.read(srsNotifierProvider.notifier).recordReview(
      'nanikiru_${state.correctDiscardId}', 'nanikiru', quality);
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

    // --- Side effects on answer confirmation ---
    if (state.isFinished && !_wasFinished) {
      _wasFinished = true;
      _panelCtrl.forward(from: 0); // 面板从底部滑入
      Future.microtask(() {
        final s = ref.read(nanikiruProvider);
        AudioService.playSlash();
        _slashCtrl.forward(from: 0);
        AnalyticsService.answered('nanikiru', s.isPerfect);

        final hearts = ref.read(heartServiceProvider);
        final eloNotifier = ref.read(eloProvider.notifier);
        if (s.isPerfect) {
          hearts.recordCorrect(); // Correct: update stats + streak
          eloNotifier.recordResult(isCorrect: true, isSkip: false);
          // Request App Store review after sustained success
          try {
            final prefs = Hive.box('prefs');
            final lastReview = prefs.get(kLastReviewKey, defaultValue: '');
            maybeRequestReview(hearts.allTimeCombo, lastReview);
            prefs.put(kLastReviewKey, DateTime.now().toIso8601String().substring(0, 10));
          } catch (_) { /* review request is best-effort */ }
          ref.read(srsNotifierProvider.notifier).recordReview(
            'nanikiru_${s.correctDiscardId}', 'nanikiru', 5);
        } else {
          hearts.recordWrong(); // Wrong: reset streak, no heart cost (wrong-answer pool for free retry)
          eloNotifier.recordResult(isCorrect: false, isSkip: false);
        }
        // Daily challenge first (free), then consume hearts
        bool depleted = false;
        if (!hearts.useDailyChallenge()) {
          depleted = hearts.consume();
        }
        if (depleted) {
          _gameOver = true;
          _maybeShowBattleReport();
        }
        // Report to leaderboard (fire-and-forget)
        final name = ref.read(playerNameProvider);
        final elo = ref.read(eloProvider);
        LeaderboardService.reportScore(name: name, elo: elo, streak: hearts.allTimeCombo);
      });
    }
    // 谜题未完成时重置 _wasFinished 标记，为下一题的上升沿检测做准备
    if (!state.isFinished) {
      _wasFinished = false;
    }

    // --- Empty / loading guard ---
    if (state.handTiles.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- Main game layout: nav → prompt → countdown → hand → toolbar ---
    return Scaffold(
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
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: TzSlashPainter(
                      progress: _slashCtrl.value,
                      color: state.isPerfect ? AppColors.neonGold : AppColors.vermillion,
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
              NanikiruFeedbackPanel(
                state: state,
                panelSlide: _panelSlide,
                onNextPuzzle: () {
                  _panelCtrl.reverse().then((_) {
                    _sessionCount++;
                    notifier.nextPuzzle();
                    _startCountdown();
                  });
                },
                onReviewAgain: () {
                  // Keep panel visible — user re-reads feedback
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Top navigation bar: back button, title, and session counter.
  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(l10n.nanikiruNavTitle, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jadeWhite,
            )),
          ),
          Text('⚔️${_sessionCount + 1}', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold,
          )),
        ],
      ),
    );
  }

  /// Drawn-tile card showing the tile the player just picked up.
  Widget _buildPrompt(NaniKiruState state) {
    final l10n = AppLocalizations.of(context)!;
    // 从牌库查询当前摸到的牌数据（用于渲染牌面文字和新牌标签）
    final drawnTile = ref.read(tileRepositoryProvider)
        .getById(state.drawnTileId, []);
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
            Text(l10n.nanikiruDraw, style: const TextStyle(
              fontSize: 13, color: AppColors.jadeWhiteDim,
            )),
            const SizedBox(height: 6),
            if (drawnTile != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    Text(drawnTile.character, style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppColors.jadeWhite,
                      fontFamily: 'Noto Serif SC',
                    )),
                    const SizedBox(width: 6),
                    Text('${drawnTile.label} ← NEW!', style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.neonGold,
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(l10n.nanikiruDiscardHint,
                style: TextStyle(
                  fontSize: 13, color: AppColors.neonGold.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  /// Countdown progress bar. Turns red and urgent below 3 seconds.
  Widget _buildCountdownBar(NaniKiruState state) {
    // 将倒计时秒数归一化为 0.0–1.0 的进度值（10秒为满值），小于等于3秒触发紧急态
    final progress = state.countdownValue / 10.0;
    final isUrgent = state.countdownValue <= 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⏱ Decision: ', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteMuted,
              )),
              Text(state.countdownValue.toStringAsFixed(1) + 's', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800,
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const Text('YOUR HAND · 14 TILES', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
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
          _toolBtn('📐 Sort', () => notifier.sortHand()),
          const SizedBox(width: 8),
          _toolBtn('💡 Hint', () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.jadeCard,
                title: const Text('💡 Hint', style: TextStyle(color: AppColors.neonGold)),
                content: Text(l10n.nanikiruHint,
                    style: const TextStyle(color: AppColors.jadeWhiteDim)),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.nanikiruGotIt, style: const TextStyle(color: AppColors.neonGold)))],
              ),
            );
          }),
          const SizedBox(width: 8),
          _toolBtn(l10n.nanikiruSkip, () {
            // 跳过流程：播放音效+动画 → 埋点上报 → 确认丢弃（isSkip=true）→ SRS记录 → ELO → 扣心
            AudioService.playSlash();
            _slashCtrl.forward(from: 0);
            AnalyticsService.answered('nanikiru', false);
            notifier.confirmDiscard(state.correctDiscardId, isSkip: true);
            _recordSrs(true); // SRS 记录：跳过计为质量=2
            ref.read(eloProvider.notifier).recordResult(isCorrect: false, isSkip: true);
            // Skip still counts as an attempt — consumes stamina
            final hearts = ref.read(heartServiceProvider);
            hearts.recordWrong(); // 重置连击统计
            bool depleted = false;
            if (!hearts.useDailyChallenge()) {
              depleted = hearts.consume();
            }
            if (depleted) {
          _gameOver = true;
          _maybeShowBattleReport();
        }
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
        child: Text(text, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteDim,
        )),
      ),
    );
  }

  /// Full-width feedback panel shown after answering.
}
