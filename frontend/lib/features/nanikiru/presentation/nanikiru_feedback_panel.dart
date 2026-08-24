/// 何切答题后的教学反馈面板。
///
/// 面板只展示规则引擎已经计算出的事实：候选弃牌排名、向听数、进张，
/// 以及由最优弃牌推导出的训练主题。它不会凭 UI 文案猜测牌姿结构。
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/nanikiru_state.dart';
import '../domain/nanikiru_teaching_analysis.dart';

class NanikiruFeedbackPanel extends StatelessWidget {
  const NanikiruFeedbackPanel({
    super.key,
    required this.state,
    required this.panelSlide,
    required this.onNextPuzzle,
    this.nextButtonLabel,
  });

  final NaniKiruState state;
  final Animation<Offset> panelSlide;
  final VoidCallback onNextPuzzle;
  final String? nextButtonLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outcome = _resolvedOutcome(state);
    final accent = _outcomeColor(outcome);
    final analysis = state.teachingAnalysis;

    return SlideTransition(
      position: panelSlide,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.92,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.jadeCard,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(top: BorderSide(color: accent, width: 2)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('nanikiru-feedback-scroll'),
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildOutcomeHeader(
                                l10n, outcome, accent, analysis),
                            if (analysis != null) ...[
                              const SizedBox(height: 22),
                              _sectionTitle(
                                l10n.nanikiruTopCandidatesTitle,
                                Icons.leaderboard_outlined,
                              ),
                              const SizedBox(height: 10),
                              _buildCandidates(l10n, analysis),
                              const SizedBox(height: 18),
                              _buildDecisionImpact(l10n, analysis, outcome),
                              const SizedBox(height: 18),
                              _buildSkills(l10n, analysis),
                              if (analysis
                                  .bestCandidate.ukeireTileIds.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                _buildUkeireTiles(l10n, analysis.bestCandidate),
                              ],
                            ] else if (state.isPerfect) ...[
                              const SizedBox(height: 18),
                              _buildPerfectTip(l10n),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildBottomAction(context, l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeHeader(
    AppLocalizations l10n,
    NaniKiruOutcome outcome,
    Color accent,
    NanikiruTeachingAnalysis? analysis,
  ) {
    final title = switch (outcome) {
      NaniKiruOutcome.perfect => l10n.nanikiruPerfect,
      NaniKiruOutcome.incorrect => l10n.nanikiruNotOptimalTitle,
      NaniKiruOutcome.skipped => l10n.nanikiruSkippedTitle,
      NaniKiruOutcome.timedOut => l10n.nanikiruTimedOutTitle,
      NaniKiruOutcome.unanswered => l10n.nanikiruNotOptimalTitle,
    };
    final icon = switch (outcome) {
      NaniKiruOutcome.perfect => Icons.check_circle_rounded,
      NaniKiruOutcome.incorrect => Icons.insights_rounded,
      NaniKiruOutcome.skipped => Icons.fast_forward_rounded,
      NaniKiruOutcome.timedOut => Icons.timer_off_outlined,
      NaniKiruOutcome.unanswered => Icons.insights_rounded,
    };

    return Column(
      children: [
        Icon(icon, color: accent, size: 34),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        if (outcome == NaniKiruOutcome.timedOut &&
            analysis?.selectedCandidate != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.nanikiruTimeoutChoice(
              analysis!.selectedCandidate!.discardId,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.jadeWhiteDim,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCandidates(
    AppLocalizations l10n,
    NanikiruTeachingAnalysis analysis,
  ) {
    final visible = [...analysis.topCandidates];
    final selected = analysis.selectedCandidate;
    final selectedOutsideTop = selected != null &&
        !visible.any((candidate) => candidate.discardId == selected.discardId);
    if (selectedOutsideTop) visible.add(selected);

    return Column(
      children: [
        for (var index = 0; index < visible.length; index++) ...[
          if (selectedOutsideTop && index == analysis.topCandidates.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(
                color: AppColors.jadeWhiteMuted.withValues(alpha: 0.35),
              ),
            ),
          _candidateCard(
            l10n,
            visible[index],
            isSelected: selected?.discardId == visible[index].discardId,
          ),
          if (index < visible.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _candidateCard(
    AppLocalizations l10n,
    NanikiruCandidateAnalysis candidate, {
    required bool isSelected,
  }) {
    final highlighted = candidate.isOptimal || isSelected;
    final borderColor = candidate.isOptimal
        ? AppColors.suitSou
        : isSelected
            ? AppColors.neonGold
            : AppColors.jadeWhiteMuted;

    return Semantics(
      container: true,
      label: l10n.nanikiruDiscardLabel(candidate.discardId),
      child: Container(
        key: ValueKey('nanikiru-candidate-${candidate.discardId}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlighted
              ? borderColor.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor.withValues(
              alpha: highlighted ? 0.62 : 0.22,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TileFace(
              tileId: candidate.discardId,
              semanticsLabel: l10n.nanikiruDiscardLabel(candidate.discardId),
            ),
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
                      Text(
                        l10n.nanikiruRankLabel(candidate.rank),
                        style: const TextStyle(
                          color: AppColors.jadeWhite,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (candidate.isOptimal)
                        _badge(l10n.nanikiruBestBadge, AppColors.suitSou),
                      if (isSelected)
                        _badge(l10n.nanikiruSelectedBadge, AppColors.neonGold),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _shantenLabel(l10n, candidate.shantenAfter),
                    style: const TextStyle(
                      color: AppColors.jadeWhiteDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.nanikiruAcceptanceSummary(
                      candidate.ukeireTypes,
                      candidate.ukeireCount,
                    ),
                    style: const TextStyle(
                      color: AppColors.jadeWhiteMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionImpact(
    AppLocalizations l10n,
    NanikiruTeachingAnalysis analysis,
    NaniKiruOutcome outcome,
  ) {
    final selected = analysis.selectedCandidate;
    final message = selected == null
        ? l10n.nanikiruNoSelection
        : selected.isOptimal
            ? l10n.nanikiruNoDecisionLoss
            : selected.shantenDifferenceFromBest > 0
                ? l10n.nanikiruShantenLoss(
                    selected.shantenDifferenceFromBest,
                  )
                : l10n.nanikiruUkeireLoss(selected.ukeireLossFromBest ?? 0);
    final isPositive = selected?.isOptimal == true &&
        outcome != NaniKiruOutcome.skipped &&
        outcome != NaniKiruOutcome.timedOut;
    final color = isPositive ? AppColors.suitSou : _outcomeColor(outcome);

    return Container(
      key: const Key('nanikiru-decision-impact'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            l10n.nanikiruDecisionLossTitle,
            Icons.analytics_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkills(
    AppLocalizations l10n,
    NanikiruTeachingAnalysis analysis,
  ) {
    final tags = analysis.optimalTags.toList()
      ..sort((left, right) => left.index.compareTo(right.index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.nanikiruSkillsTitle, Icons.school_outlined),
        const SizedBox(height: 9),
        Wrap(
          key: const Key('nanikiru-skill-tags'),
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.celadonBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.celadonLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _skillLabel(l10n, tag),
                  style: const TextStyle(
                    color: AppColors.celadonLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUkeireTiles(
    AppLocalizations l10n,
    NanikiruCandidateAnalysis best,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          l10n.nanikiruAcceptanceGridTitle,
          Icons.grid_view_rounded,
        ),
        const SizedBox(height: 9),
        Wrap(
          key: const Key('nanikiru-acceptance-tiles'),
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tileId in best.ukeireTileIds)
              _TileFace(
                tileId: tileId,
                semanticsLabel: l10n.nanikiruDiscardLabel(tileId),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerfectTip(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.suitSou.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.neonGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.nanikiruPerfectExplain,
              style: const TextStyle(
                color: AppColors.jadeWhiteDim,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.jadeCard,
        border: Border(
          top: BorderSide(
            color: AppColors.jadeWhiteMuted.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: const Key('nanikiru-next-button'),
          onPressed: onNextPuzzle,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonGold,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            nextButtonLabel ?? l10n.nanikiruNextPuzzle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.jadeWhiteDim, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.jadeWhiteDim,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _shantenLabel(AppLocalizations l10n, int shanten) =>
      shanten == 0 ? l10n.nanikiruTenpai : l10n.nanikiruShantenValue(shanten);

  String _skillLabel(AppLocalizations l10n, NanikiruTeachingTag tag) =>
      switch (tag) {
        NanikiruTeachingTag.isolatedTileHandling =>
          l10n.nanikiruSkillIsolatedTile,
        NanikiruTeachingTag.taatsuOverload => l10n.nanikiruSkillTaatsuOverload,
        NanikiruTeachingTag.pairProtection => l10n.nanikiruSkillPairProtection,
        NanikiruTeachingTag.chiitoitsuCompetition =>
          l10n.nanikiruSkillChiitoitsu,
        NanikiruTeachingTag.kokushiTendency => l10n.nanikiruSkillKokushi,
        NanikiruTeachingTag.generalTileEfficiency =>
          l10n.nanikiruSkillGeneralEfficiency,
      };

  NaniKiruOutcome _resolvedOutcome(NaniKiruState state) {
    if (state.outcome != NaniKiruOutcome.unanswered) return state.outcome;
    return state.isPerfect
        ? NaniKiruOutcome.perfect
        : NaniKiruOutcome.incorrect;
  }

  Color _outcomeColor(NaniKiruOutcome outcome) => switch (outcome) {
        NaniKiruOutcome.perfect => AppColors.suitSou,
        NaniKiruOutcome.incorrect => AppColors.vermillion,
        NaniKiruOutcome.skipped => AppColors.celadonLight,
        NaniKiruOutcome.timedOut => AppColors.neonGold,
        NaniKiruOutcome.unanswered => AppColors.jadeWhiteMuted,
      };
}

class _TileFace extends StatelessWidget {
  const _TileFace({required this.tileId, required this.semanticsLabel});

  final String tileId;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: Container(
        width: 38,
        height: 52,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.jadeWhite,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SvgPicture.asset(
          'assets/tiles/$tileId.svg',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
