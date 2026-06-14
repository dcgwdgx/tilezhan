/// 何切（牌效率选择）屏幕 — ELO 难度匹配 + 斜切动画。
///
/// 手牌展示 + 倒计时条 + 切牌确认/跳过 + 计费逻辑。
/// 正确 = 更新战绩 + 扣心；错误 = 进错题池不扣心。

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/audio_service.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../shared/widgets/tz_battle_report.dart';
import '../../../shared/widgets/tz_combo_promo.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../../shared/widgets/tz_slash_painter.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../domain/nanikiru_provider.dart';
import '../domain/nanikiru_state.dart';

class NanikiruScreen extends ConsumerStatefulWidget {
  const NanikiruScreen({super.key});

  @override
  ConsumerState<NanikiruScreen> createState() => _NanikiruScreenState();
}

class _NanikiruScreenState extends ConsumerState<NanikiruScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _slashCtrl;
  int _sessionCount = 0;

  @override
  void initState() {
    super.initState();
    _slashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    Future.microtask(() {
      // 免费用户体力/每日挑战耗尽时弹窗，不生成新题
      if (!ref.read(canPlayProvider)) {
        _maybeShowBattleReport();
        return;
      }
      ref.read(nanikiruProvider.notifier).initPuzzle();
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slashCtrl.dispose();
    super.dispose();
  }

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

  /// 弹战绩或 10 连斩促销窗口。付费用户跳过。
  void _maybeShowBattleReport() {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return;
    if (ref.read(showComboPromoProvider)) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const TzComboPromo(),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TzBattleReport(),
    );
  }

  /// 追踪 isFinished 翻转 → 在下一帧记录战绩、扣体力、弹窗。
  bool _wasFinished = false;

  void _recordSrs(bool isSkip) {
    final state = ref.read(nanikiruProvider);
    final quality = state.isPerfect ? 5 : (isSkip ? 2 : 1);
    ref.read(srsNotifierProvider.notifier).recordReview(
      'nanikiru_${state.correctDiscardId}', 'nanikiru', quality);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nanikiruProvider);
    final notifier = ref.read(nanikiruProvider.notifier);

    // 手动确认打出牌 → 战绩 + 扣体力 + 弹窗
    if (state.isFinished && !_wasFinished) {
      _wasFinished = true;
      Future.microtask(() {
        final s = ref.read(nanikiruProvider);
        AudioService.playSlash();
        _slashCtrl.forward(from: 0);
        AnalyticsService.answered('nanikiru', s.isPerfect);

        final hearts = ref.read(heartServiceProvider);
        if (s.isPerfect) {
          hearts.recordCorrect(); // 正确：更新战绩 + 连斩
          ref.read(srsNotifierProvider.notifier).recordReview(
            'nanikiru_${s.correctDiscardId}', 'nanikiru', 5);
        } else {
          hearts.recordWrong(); // 错误：归零连斩，不耗心（进错题池免费重练）
        }
        // 每日挑战优先（免费），其次消耗心数
        bool depleted = false;
        if (!hearts.useDailyChallenge()) {
          depleted = hearts.consume();
        }
        if (depleted) _maybeShowBattleReport();
      });
    }
    if (!state.isFinished) {
      _wasFinished = false;
    }

    if (state.handTiles.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

  Widget _buildPrompt(NaniKiruState state) {
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
            const Text('You just drew:', style: TextStyle(
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

  Widget _buildCountdownBar(NaniKiruState state) {
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

  Widget _buildToolbar(NaniKiruState state, NanikiruNotifier notifier) {
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
                content: const Text('Look for sequences and triplets.\nDiscard isolated tiles that don\'t form any meld.\nThe correct answer maximizes tile acceptance (ukeire).',
                    style: TextStyle(color: AppColors.jadeWhiteDim)),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it', style: TextStyle(color: AppColors.neonGold)))],
              ),
            );
          }),
          const SizedBox(width: 8),
          _toolBtn('🏳️ Skip', () {
            AudioService.playSlash();
            _slashCtrl.forward(from: 0);
            AnalyticsService.answered('nanikiru', false);
            notifier.confirmDiscard(state.correctDiscardId, isSkip: true);
            _recordSrs(true);
            // 跳过也算尝试，消耗体力
            final hearts = ref.read(heartServiceProvider);
            hearts.recordWrong(); // 归零连斩
            bool depleted = false;
            if (!hearts.useDailyChallenge()) {
              depleted = hearts.consume();
            }
            if (depleted) _maybeShowBattleReport();
          }),
        ],
      ),
    );
  }

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

  Widget _buildFeedbackSheet(NaniKiruState state, NanikiruNotifier notifier) {
    final isPerfect = state.isPerfect;
    return GestureDetector(
      onTap: () {
        _sessionCount++;
        notifier.nextPuzzle();
        _startCountdown();
      },
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
                Text(isPerfect ? '🎯 PERFECT!' : '💥 BLUNDER!', style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w900,
                  color: isPerfect ? const Color(0xFF2CE574) : AppColors.vermillion,
                  shadows: [Shadow(
                    color: (isPerfect ? const Color(0xFF2CE574) : AppColors.vermillion).withOpacity(0.4),
                    blurRadius: 12,
                  )],
                )),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat('${state.ukeireCount}', isPerfect ? 'Acceptance Tiles' : 'Your Pick'),
                  _stat('${state.ukeireTypes}', 'Types'),
                  _stat(isPerfect ? 'Tenpai!' : '-7 tiles', 'Shanten'),
                ]),
                if (!isPerfect) ...[
                  const SizedBox(height: 12),
                  Text('Correct discard: ${state.correctDiscardId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2CE574))),
                ],
                const SizedBox(height: 20),
                Text('Tap anywhere to continue', style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteMuted.withOpacity(0.5))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

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
