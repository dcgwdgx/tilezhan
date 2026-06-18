/// 何切（牌效率选择）屏幕 — ELO 难度匹配 + 斜切动画。
///
/// 手牌展示 + 倒计时条 + 切牌确认/跳过 + 计费逻辑。
/// 正确 = 更新战绩 + 扣心；错误 = 进错题池不扣心。

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/elo/elo_provider.dart';
import '../../../core/providers/player_name_provider.dart';
import '../../../core/utils/audio_service.dart';
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
              _buildFeedbackSheet(state, notifier),
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
          const Expanded(
            child: Text('Nani-Kiru · Two-Sided Waits', style: TextStyle(
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
            Text('Discard 1 tile for max efficiency',
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
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it', style: TextStyle(color: AppColors.neonGold)))],
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
  ///
  /// Slides up from the bottom via [_panelSlide] animation (350ms easeOutCubic).
  /// Displays PERFECT or BLUNDER header, stats row using real ukeire data,
  /// a comparison bar, acceptance tile grid, explanation text, and explicit
  /// [Next Puzzle] / [Review Again] buttons (replaces the old auto-advance tap).
  Widget _buildFeedbackSheet(NaniKiruState state, NanikiruNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    final isPerfect = state.isPerfect;

    // Read per-discard ukeire from state for real-data comparison.
    final allUkeire = state.allDiscardUkeire ?? {};
    final selUkeire = allUkeire[state.selectedTileId] ?? 0;
    final correctUkeire = allUkeire[state.correctDiscardId] ?? state.ukeireCount ?? 0;

    return SlideTransition(
      position: _panelSlide,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7), Colors.black87],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: isPerfect
                      ? [const Color(0xFF0A2F1D), const Color(0xFF0D3D26)]
                      : [const Color(0xFF2A0F0F), const Color(0xFF1A0806)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: isPerfect ? const Color(0xFF2CE574) : AppColors.vermillion, width: 2),
                ),
                boxShadow: [BoxShadow(
                  color: (isPerfect ? const Color(0xFF2CE574) : AppColors.vermillion).withOpacity(0.2),
                  blurRadius: 20, offset: const Offset(0, -4),
                )],
              ),
              child: Column(children: [
                // ── 结果标题 ──
                Text(isPerfect ? l10n.nanikiruPerfect : l10n.nanikiruBlunder, style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w900,
                  color: isPerfect ? const Color(0xFF2CE574) : AppColors.vermillion,
                  shadows: [Shadow(
                    color: (isPerfect ? const Color(0xFF2CE574) : AppColors.vermillion).withOpacity(0.4),
                    blurRadius: 12,
                  )],
                )),
                const SizedBox(height: 16),

                // ── 统计数据行：使用真实进张数据 ──
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat('${isPerfect ? correctUkeire : selUkeire}',
                    isPerfect ? l10n.nanikiruAcceptanceTiles : l10n.nanikiruYourDiscardLabel),
                  _stat('${state.ukeireTypes ?? 0}', 'Types'),
                  _stat(isPerfect ? 'Tenpai!' : '$correctUkeire best', l10n.nanikiruBestDiscardLabel),
                ]),

                // ── 进张对比条（答错时显示）──
                if (!isPerfect) ...[
                  const SizedBox(height: 16),
                  _buildComparisonBar(selUkeire, correctUkeire, allUkeire),
                ],

                // ── 复盘面板：对比用户选择与最优解 ──
                if (!isPerfect) ...[
                  const SizedBox(height: 12),
                  _buildReviewCard(state),
                ],

                // ── 进张牌网格 ──
                if ((isPerfect || !isPerfect) && correctUkeire > 0) ...[
                  const SizedBox(height: 12),
                  _buildUkeireTileGrid(state),
                ],

                // ── 正确答案提示（答对时）──
                if (isPerfect) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2CE574).withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.neonGold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l10n.nanikiruPerfectExplain,
                        style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim, height: 1.5))),
                    ]),
                  ),
                ],

                // ── 操作按钮：Next Puzzle / Review Again ──
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _toolBtn(l10n.nanikiruReviewAgain, () {
                    // Keep the panel visible — no state change, user re-reads feedback
                  }),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      _panelCtrl.reverse().then((_) {
                        _sessionCount++;
                        notifier.nextPuzzle();
                        _startCountdown();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(l10n.nanikiruNextPuzzle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// Visual comparison bar: user's ukeire (red) vs correct discard (green)
  /// normalized against the max ukeire across all possible discards.
  Widget _buildComparisonBar(int selUkeire, int correctUkeire, Map<String, int> allUkeire) {
    final maxUkeire = allUkeire.values.isNotEmpty
        ? allUkeire.values.reduce((a, b) => a > b ? a : b).toDouble()
        : correctUkeire.toDouble();
    final selRatio = maxUkeire > 0 ? (selUkeire / maxUkeire).clamp(0.0, 1.0) : 0.0;
    final correctRatio = maxUkeire > 0 ? (correctUkeire / maxUkeire).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.nanikiruAcceptanceComparison,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 10),
        // User discard bar
        Row(children: [
          SizedBox(width: 48, child: Text(l10n.nanikiruYourDiscardLabel,
            style: const TextStyle(fontSize: 10, color: AppColors.vermillion))),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: selRatio, minHeight: 14,
              backgroundColor: AppColors.vermillion.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.vermillion),
            ),
          )),
          const SizedBox(width: 8),
          Text('$selUkeire', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.vermillion)),
        ]),
        const SizedBox(height: 6),
        // Best discard bar
        Row(children: [
          SizedBox(width: 48, child: Text(l10n.nanikiruBestDiscardLabel,
            style: const TextStyle(fontSize: 10, color: Color(0xFF2CE574)))),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: correctRatio, minHeight: 14,
              backgroundColor: const Color(0xFF2CE574).withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2CE574)),
            ),
          )),
          const SizedBox(width: 8),
          Text('$correctUkeire', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2CE574))),
        ]),
      ]),
    );
  }

  /// Comparison card showing user's discard vs correct discard with
  /// data-driven explanation text (uses real ukeire from state).
  Widget _buildReviewCard(NaniKiruState state) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.vermillion.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AppColors.vermillion)),
          const SizedBox(width: 8),
          Text(l10n.nanikiruYourDiscard(state.selectedTileId ?? "—"),
            style: const TextStyle(fontSize: 14, color: AppColors.vermillion)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFF2CE574))),
          const SizedBox(width: 8),
          Expanded(child: Text(
            l10n.nanikiruBestDiscard(state.correctDiscardId, state.allDiscardUkeire?[state.correctDiscardId] ?? state.ukeireCount ?? 0, state.ukeireTypes ?? 0),
            style: const TextStyle(fontSize: 14, color: Color(0xFF2CE574)))),
        ]),
        const SizedBox(height: 12),
        Text(
          _getWhyExplanation(state),
          style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim, height: 1.5),
        ),
      ]),
    );
  }

  /// Grid of mini TzTile widgets showing the acceptance tiles for the correct discard.
  Widget _buildUkeireTileGrid(NaniKiruState state) {
    final allTiles = state.allDiscardUkeireTiles ?? {};
    final correctTiles = allTiles[state.correctDiscardId] ?? state.ukeireTiles ?? [];
    if (correctTiles.isEmpty) return const SizedBox.shrink();

    final repo = ref.read(tileRepositoryProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Acceptance Tiles',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 3, runSpacing: 3,
          children: correctTiles.map((id) {
            final tile = repo.getById(id, []);
            return tile != null
                ? TzTile(tile: tile, size: TileSize.sm, state: TileState.normal)
                : const SizedBox.shrink();
          }).toList(),
        ),
      ]),
    );
  }

  /// Data-driven explanation for why the correct discard is better.
  ///
  /// Uses real per-discard ukeire from [NaniKiruState.allDiscardUkeire]
  /// instead of the old +6 heuristic. Categorizes the gap into three tiers.
  String _getWhyExplanation(NaniKiruState state) {
    final selected = state.selectedTileId ?? '';
    final correct = state.correctDiscardId;
    if (selected == correct) return 'Perfect choice! This discard maximizes your tile acceptance.';

    final allUkeire = state.allDiscardUkeire ?? {};
    final selUke = allUkeire[selected] ?? 0;
    final correctUke = allUkeire[correct] ?? state.ukeireCount ?? 0;
    final diff = correctUke - selUke;

    if (diff >= 8) {
      return 'The correct discard $correct opens up $correctUke acceptance tiles, while $selected only gives $selUke. '
          '$correct is an isolated tile that doesn\'t break any melds.';
    } else if (diff >= 3) {
      return '$correct offers ${diff} more acceptance tiles than $selected. '
          'It keeps your best meld candidates intact.';
    } else {
      return '$correct keeps your hand structure stronger. It preserves key sequences while $selected breaks a useful group.';
    }
  }

  /// Small stat column: large value text above a muted label.
  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.jadeWhite,
        )),
        Text(label, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteMuted,
        )),
      ],
    );
  }
}
