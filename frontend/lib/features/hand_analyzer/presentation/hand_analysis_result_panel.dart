import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../domain/hand_analysis_history.dart';
import '../domain/hand_analyzer.dart';

/// Engine-backed result for a manually entered hand.
class HandAnalysisResultPanel extends StatelessWidget {
  const HandAnalysisResultPanel({
    super.key,
    required this.analysis,
    required this.tilesById,
    required this.onSave,
  });

  final HandAnalysis analysis;
  final Map<String, TileModel> tilesById;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      key: const ValueKey('hand-analyzer-engine-result'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.jadeCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: AppColors.neonGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.handAnalyzerCurrentShanten,
                  style: const TextStyle(
                    color: AppColors.jadeWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MetricPill(
                value: formatHandAnalyzerShanten(
                  l10n,
                  analysis.minimumShanten,
                ),
                highlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ShapeBreakdown(analysis: analysis),
          const SizedBox(height: 18),
          if (analysis case final DrawHandAnalysis drawAnalysis)
            _DrawAnalysisBody(
              analysis: drawAnalysis,
              tilesById: tilesById,
            )
          else if (analysis case final DiscardHandAnalysis discardAnalysis)
            _DiscardAnalysisBody(
              analysis: discardAnalysis,
              tilesById: tilesById,
            ),
          const SizedBox(height: 18),
          TzButton(
            key: const ValueKey('hand-analyzer-save'),
            label: l10n.handAnalyzerSave,
            icon: Icons.bookmark_add_outlined,
            style: TzButtonStyle.ghost,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

/// Recent inputs are stored without calculated facts and recomputed when opened.
class HandAnalysisHistoryPanel extends StatelessWidget {
  const HandAnalysisHistoryPanel({
    super.key,
    required this.records,
    required this.tilesById,
    required this.onOpen,
    required this.onDelete,
  });

  final List<HandAnalysisRecord> records;
  final Map<String, TileModel> tilesById;
  final ValueChanged<HandAnalysisRecord> onOpen;
  final ValueChanged<HandAnalysisRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('hand-analyzer-history'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.jadeCard.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.jadeHover),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.handAnalyzerRecent,
            style: const TextStyle(
              color: AppColors.jadeWhite,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.handAnalyzerRecentEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.jadeWhiteMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            for (final record in records) ...[
              _HistoryRecordCard(
                record: record,
                tilesById: tilesById,
                onOpen: () => onOpen(record),
                onDelete: () => onDelete(record),
              ),
              if (record != records.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ShapeBreakdown extends StatelessWidget {
  const _ShapeBreakdown({required this.analysis});

  final HandAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final values = [
      (l10n.handAnalyzerStandard, analysis.shantenBreakdown.standard),
      (l10n.handAnalyzerSevenPairs, analysis.shantenBreakdown.sevenPairs),
      (
        l10n.handAnalyzerThirteenOrphans,
        analysis.shantenBreakdown.thirteenOrphans,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.handAnalyzerShapeBreakdown,
          style: const TextStyle(
            color: AppColors.jadeWhiteDim,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.$1,
                    style: const TextStyle(
                      color: AppColors.jadeWhiteDim,
                      fontSize: 12,
                    ),
                  ),
                ),
                _MetricPill(
                  value: formatHandAnalyzerShanten(l10n, value.$2),
                  highlighted: value.$2 == analysis.minimumShanten,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DrawAnalysisBody extends StatelessWidget {
  const _DrawAnalysisBody({
    required this.analysis,
    required this.tilesById,
  });

  final DrawHandAnalysis analysis;
  final Map<String, TileModel> tilesById;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.handAnalyzerImprovingTiles,
          style: const TextStyle(
            color: AppColors.jadeWhite,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.handAnalyzerEffectiveSummary(
            analysis.effectiveTileTypeCount,
            analysis.totalEffectiveTileCount,
          ),
          style: const TextStyle(
            color: AppColors.neonGold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (analysis.effectiveDraws.isEmpty)
          Text(
            l10n.handAnalyzerNoImprovingTiles,
            style: const TextStyle(color: AppColors.jadeWhiteMuted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final draw in analysis.effectiveDraws)
                _TileWithCount(
                  tile: tilesById[draw.tileId]!,
                  count: draw.theoreticalRemainingCopies,
                ),
            ],
          ),
      ],
    );
  }
}

class _DiscardAnalysisBody extends StatelessWidget {
  const _DiscardAnalysisBody({
    required this.analysis,
    required this.tilesById,
  });

  final DiscardHandAnalysis analysis;
  final Map<String, TileModel> tilesById;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final handCounts = <String, int>{};
    for (final tileId in analysis.handTiles) {
      handCounts[tileId] = (handCounts[tileId] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.handAnalyzerDiscardCandidates,
          style: const TextStyle(
            color: AppColors.jadeWhite,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        for (final candidate in analysis.candidates) ...[
          _DiscardCandidateCard(
            candidate: candidate,
            discardTile: tilesById[candidate.tileId]!,
            tilesById: tilesById,
            visibleCounts: handCounts,
          ),
          if (candidate != analysis.candidates.last)
            const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DiscardCandidateCard extends StatelessWidget {
  const _DiscardCandidateCard({
    required this.candidate,
    required this.discardTile,
    required this.tilesById,
    required this.visibleCounts,
  });

  final DiscardCandidate candidate;
  final TileModel discardTile;
  final Map<String, TileModel> tilesById;
  final Map<String, int> visibleCounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: ValueKey('hand-analyzer-candidate-${candidate.tileId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: candidate.isOptimal
            ? AppColors.neonGold.withValues(alpha: 0.09)
            : AppColors.jadeDeep.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: candidate.isOptimal
              ? AppColors.neonGold.withValues(alpha: 0.55)
              : AppColors.jadeHover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TzTile(tile: discardTile, size: TileSize.sm),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetricPill(
                          value: l10n.handAnalyzerRank(candidate.rank),
                          highlighted: candidate.isOptimal,
                        ),
                        if (candidate.isOptimal)
                          _MetricPill(
                            value: l10n.handAnalyzerBest,
                            highlighted: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      l10n.handAnalyzerCandidateSummary(
                        formatHandAnalyzerShanten(
                          l10n,
                          candidate.minimumShantenAfterDiscard,
                        ),
                        candidate.effectiveTileTypeCount,
                        candidate.effectiveTileCount,
                      ),
                      style: const TextStyle(
                        color: AppColors.jadeWhiteDim,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (candidate.effectiveTileIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final tileId in candidate.effectiveTileIds)
                  _TileWithCount(
                    tile: tilesById[tileId]!,
                    count: 4 - (visibleCounts[tileId] ?? 0),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TileWithCount extends StatelessWidget {
  const _TileWithCount({required this.tile, required this.count});

  final TileModel tile;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TzTile(tile: tile, size: TileSize.sm),
        PositionedDirectional(
          end: -5,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neonGold,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.jadeDeep, width: 1.5),
            ),
            child: Text(
              '×$count',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.record,
    required this.tilesById,
    required this.onOpen,
    required this.onDelete,
  });

  final HandAnalysisRecord record;
  final Map<String, TileModel> tilesById;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: ValueKey('hand-analyzer-history-${record.id}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.jadeDeep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.jadeHover),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: record.tileIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, index) => TzTile(
                tile: tilesById[record.tileIds[index]]!,
                size: TileSize.sm,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new, size: 17),
                label: Text(l10n.handAnalyzerOpen),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 17),
                label: Text(l10n.handAnalyzerDelete),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.vermillion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.value, required this.highlighted});

  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.neonGold : AppColors.jadeWhiteMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String formatHandAnalyzerShanten(AppLocalizations l10n, int shanten) {
  if (shanten < 0) return l10n.handAnalyzerComplete;
  if (shanten == 0) return l10n.handAnalyzerTenpai;
  return l10n.handAnalyzerShantenValue(shanten);
}
