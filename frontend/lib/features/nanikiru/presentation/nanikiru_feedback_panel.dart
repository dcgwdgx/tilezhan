/// 何切复盘反馈面板 — 从 [NanikiruScreen] 拆分出的独立组件。
///
/// 接管答题后全部 UI：结果标题、进张对比条、复盘卡片、
/// 进张牌网格、Next Puzzle / Review Again 按钮。
/// 从底部滑入（[SlideTransition]），350ms easeOutCubic。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../domain/nanikiru_state.dart';

/// 反馈面板组件。
///
/// 参数：
/// - [state]：当前谜题状态，含 isPerfect / allDiscardUkeire 等数据。
/// - [panelSlide]：面板从底部滑入的位移动画（Offset(0,1)→Offset.zero）。
/// - [onNextPuzzle]：点击 Next Puzzle 的回调（含面板收起动画）。
/// - [onReviewAgain]：点击 Review Again 的回调（保持面板不动）。
class NanikiruFeedbackPanel extends ConsumerWidget {
  final NaniKiruState state;
  final Animation<Offset> panelSlide;
  final VoidCallback onNextPuzzle;

  const NanikiruFeedbackPanel({
    super.key,
    required this.state,
    required this.panelSlide,
    required this.onNextPuzzle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPerfect = state.isPerfect;
    final allUkeire = state.allDiscardUkeire ?? {};
    final selUkeire = allUkeire[state.selectedTileId] ?? 0;
    final correctUkeire = allUkeire[state.correctDiscardId] ?? state.ukeireCount ?? 0;

    return SlideTransition(
      position: panelSlide,
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
                  shadows: [Shadow(color: (isPerfect ? const Color(0xFF2CE574) : AppColors.vermillion).withOpacity(0.4), blurRadius: 12)],
                )),
                const SizedBox(height: 16),

                // ── 统计数据行 ──
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat('${isPerfect ? correctUkeire : selUkeire}',
                    isPerfect ? l10n.nanikiruAcceptanceTiles : l10n.nanikiruYourDiscardLabel),
                  _stat('${state.ukeireTypes ?? 0}', 'Types'),
                  _stat(correctUkeire.toString(), l10n.nanikiruBestDiscardLabel),
                ]),

                // ── 进张对比条（答错时）──
                if (!isPerfect) ...[
                  const SizedBox(height: 16),
                  _buildComparisonBar(l10n, selUkeire, correctUkeire, allUkeire),
                ],

                // ── 复盘卡片 ──
                if (!isPerfect) ...[
                  const SizedBox(height: 12),
                  _buildReviewCard(l10n),
                ],

                // ── 进张牌网格 ──
                if (correctUkeire > 0) ...[
                  const SizedBox(height: 12),
                  _buildUkeireTileGrid(state, ref, l10n),
                ],

                // ── 答对提示 ──
                if (isPerfect) ...[
                  const SizedBox(height: 16),
                  _buildPerfectTip(l10n),
                ],

                // ── 按钮 ──
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onNextPuzzle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(l10n.nanikiruNextPuzzle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonBar(AppLocalizations l10n, int selUkeire, int correctUkeire, Map<String, int> allUkeire) {
    final maxUkeire = allUkeire.values.isNotEmpty
        ? allUkeire.values.reduce((a, b) => a > b ? a : b).toDouble()
        : correctUkeire.toDouble();
    final selRatio = maxUkeire > 0 ? (selUkeire / maxUkeire).clamp(0.0, 1.0) : 0.0;
    final correctRatio = maxUkeire > 0 ? (correctUkeire / maxUkeire).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.nanikiruAcceptanceComparison, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 10),
        _bar(l10n.nanikiruYourDiscardLabel, selUkeire, selRatio, AppColors.vermillion),
        const SizedBox(height: 6),
        _bar(l10n.nanikiruBestDiscardLabel, correctUkeire, correctRatio, const Color(0xFF2CE574)),
      ]),
    );
  }

  Widget _bar(String label, int count, double ratio, Color color) {
    return Row(children: [
      SizedBox(width: 48, child: Text(label, style: TextStyle(fontSize: 10, color: color))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: ratio, minHeight: 14,
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      )),
      const SizedBox(width: 8),
      Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _buildReviewCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.vermillion.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.vermillion)),
          const SizedBox(width: 8),
          Text(l10n.nanikiruYourDiscard(state.selectedTileId ?? "—"), style: const TextStyle(fontSize: 14, color: AppColors.vermillion)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2CE574))),
          const SizedBox(width: 8),
          Expanded(child: Text(
            l10n.nanikiruBestDiscard(state.correctDiscardId, state.allDiscardUkeire?[state.correctDiscardId] ?? state.ukeireCount ?? 0, state.ukeireTypes ?? 0),
            style: const TextStyle(fontSize: 14, color: Color(0xFF2CE574)))),
        ]),
        const SizedBox(height: 12),
        Text(_getWhyExplanation(), style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim, height: 1.5)),
      ]),
    );
  }

  String _getWhyExplanation() {
    final selected = state.selectedTileId ?? '';
    final correct = state.correctDiscardId;
    if (selected == correct) return 'Perfect choice! This discard maximizes your tile acceptance.';
    final allUkeire = state.allDiscardUkeire ?? {};
    final selUke = allUkeire[selected] ?? 0;
    final correctUke = allUkeire[correct] ?? state.ukeireCount ?? 0;
    final diff = correctUke - selUke;
    if (diff >= 8) {
      return 'The correct discard $correct opens up $correctUke acceptance tiles, while $selected only gives $selUke. $correct is an isolated tile that doesn\'t break any melds.';
    } else if (diff >= 3) {
      return '$correct offers ${diff} more acceptance tiles than $selected. It keeps your best meld candidates intact.';
    } else {
      return '$correct keeps your hand structure stronger. It preserves key sequences while $selected breaks a useful group.';
    }
  }

  Widget _buildUkeireTileGrid(NaniKiruState state, WidgetRef ref, AppLocalizations l10n) {
    final allTiles = state.allDiscardUkeireTiles ?? {};
    final correctTiles = allTiles[state.correctDiscardId] ?? state.ukeireTiles ?? [];
    if (correctTiles.isEmpty) return const SizedBox.shrink();
    final repo = ref.read(tileRepositoryProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.nanikiruAcceptanceGridTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 8),
        Wrap(spacing: 3, runSpacing: 3, children: correctTiles.map((id) {
          final tile = repo.getById(id, []);
          return tile != null ? TzTile(tile: tile, size: TileSize.sm, state: TileState.normal) : const SizedBox.shrink();
        }).toList()),
      ]),
    );
  }

  Widget _buildPerfectTip(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2CE574).withOpacity(0.2))),
      child: Row(children: [
        const Icon(Icons.lightbulb_outline, color: AppColors.neonGold, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(l10n.nanikiruPerfectExplain,
          style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim, height: 1.5))),
      ]),
    );
  }

  Widget _stat(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.jadeWhite)),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.jadeWhiteMuted)),
    ]);
  }
}
