import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_card.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../domain/defense_trainer.dart';
import '../domain/defense_training_state.dart';

typedef DefenseAnswerRecorded = void Function(DefenseTrainingAnswer answer);

/// A complete offline defense-training session.
///
/// Persistence, hearts, purchases, and routing are intentionally injected or
/// left to the owning feature shell. This screen owns only session interaction.
class DefenseTrainingScreen extends ConsumerStatefulWidget {
  const DefenseTrainingScreen({
    super.key,
    this.reviewQuestionId,
    this.focusTopic,
    this.questionLimit,
    this.seed,
    this.catalog,
    this.onAnswerRecorded,
    this.onCancel,
    this.onDone,
  });

  final String? reviewQuestionId;
  final DefenseTopic? focusTopic;
  final int? questionLimit;
  final int? seed;
  final List<DefenseQuestion>? catalog;
  final DefenseAnswerRecorded? onAnswerRecorded;
  final VoidCallback? onCancel;
  final VoidCallback? onDone;

  @override
  ConsumerState<DefenseTrainingScreen> createState() =>
      _DefenseTrainingScreenState();
}

class _DefenseTrainingScreenState extends ConsumerState<DefenseTrainingScreen> {
  late int _seed;
  late DefenseTrainingState _session;
  bool _sessionLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    _loadSession(_seed);
  }

  void _loadSession(int seed) {
    try {
      _session = _createSession(seed);
      _sessionLoadFailed = false;
    } on ArgumentError {
      _sessionLoadFailed = true;
    } on StateError {
      _sessionLoadFailed = true;
    }
  }

  DefenseTrainingState _createSession(int seed) {
    final reviewQuestionId = widget.reviewQuestionId;
    if (reviewQuestionId != null) {
      return DefenseTrainingState.review(
        reviewQuestionId: reviewQuestionId,
        seed: seed,
        catalog: widget.catalog,
      );
    }
    if (widget.focusTopic != null) {
      return DefenseTrainingState.focused(
        topic: widget.focusTopic!,
        seed: seed,
        catalog: widget.catalog,
        questionLimit: widget.questionLimit,
      );
    }
    return DefenseTrainingState.standard(
      seed: seed,
      catalog: widget.catalog,
      questionLimit: widget.questionLimit,
    );
  }

  void _begin() {
    setState(() => _session = _session.begin());
  }

  void _submit(String choiceId) {
    final before = _session;
    final next = before.submit(choiceId);
    if (identical(next, before)) return;
    setState(() => _session = next);
    widget.onAnswerRecorded?.call(next.currentAnswer!);
  }

  void _next() {
    setState(() => _session = _session.next());
  }

  void _restart() {
    _seed += 1;
    setState(() => _loadSession(_seed));
  }

  void _retrySession() {
    setState(() => _loadSession(_seed));
  }

  void _done() {
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = _sessionLoadFailed
        ? _LoadError(
            message: l10n.defenseLoadError,
            retryLabel: l10n.defenseRetry,
            onRetry: _retrySession,
            secondaryLabel: l10n.defenseDone,
            onSecondary: _cancel,
          )
        : switch (_session.phase) {
            DefenseTrainingPhase.intro => _buildIntro(l10n),
            DefenseTrainingPhase.completed => _buildSummary(l10n),
            DefenseTrainingPhase.answering ||
            DefenseTrainingPhase.revealed =>
              _buildQuestionWithTiles(l10n),
          };
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: _cancel,
          icon: const Icon(Icons.close, color: AppColors.jadeWhiteDim),
        ),
        title: Text(
          l10n.defenseTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.jadeWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: body,
      ),
    );
  }

  Widget _buildIntro(AppLocalizations l10n) {
    return ListView(
      key: const ValueKey('defense-intro-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 58,
          color: AppColors.neonGold,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.defenseIntroTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.jadeWhite,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.defenseIntroBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.jadeWhiteDim,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        TzCard(
          goldBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.neonGold,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      l10n.defenseScope,
                      style: const TextStyle(
                        color: AppColors.jadeWhiteDim,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                key: const ValueKey('defense-topic-chips'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final topic in widget.focusTopic == null
                      ? DefenseTopic.values
                      : <DefenseTopic>[widget.focusTopic!])
                    _TopicChip(label: _topicLabel(l10n, topic)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.defenseSessionLength(_session.totalCount),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.jadeWhiteMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TzButton(
          key: const ValueKey('defense-start'),
          label: l10n.defenseStart,
          icon: Icons.play_arrow_rounded,
          style: TzButtonStyle.gold,
          onPressed: _begin,
        ),
      ],
    );
  }

  Widget _buildQuestionWithTiles(AppLocalizations l10n) {
    final tileData = ref.watch(tileDataProvider);
    return tileData.when(
      data: (tiles) {
        final byId = {for (final tile in tiles) tile.id: tile};
        final question = _session.currentQuestion!;
        final requiredIds = <String>{
          ...question.discardsBySeat.values.expand((river) => river),
          ...question.additionalPublicVisibleCounts.keys,
          ...question.choices.map((choice) => choice.tileId),
        };
        if (requiredIds.any((tileId) => !byId.containsKey(tileId))) {
          return _LoadError(
            message: l10n.defenseLoadError,
            retryLabel: l10n.defenseRetry,
            onRetry: () => ref.invalidate(tileDataProvider),
          );
        }
        return _buildQuestion(l10n, question, byId);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonGold),
      ),
      error: (_, __) => _LoadError(
        message: l10n.defenseLoadError,
        retryLabel: l10n.defenseRetry,
        onRetry: () => ref.invalidate(tileDataProvider),
      ),
    );
  }

  Widget _buildQuestion(
    AppLocalizations l10n,
    DefenseQuestion question,
    Map<String, TileModel> tilesById,
  ) {
    final progressLabel = l10n.defenseProgress(
      _session.currentIndex + 1,
      _session.totalCount,
    );
    final progress = (_session.currentIndex + 1) / _session.totalCount;
    final otherRivers = question.discardsBySeat.entries
        .where((entry) => entry.key != question.targetSeat)
        .toList()
      ..sort((left, right) => left.key.index.compareTo(right.key.index));

    return ListView(
      key: const ValueKey('defense-question-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TopicChip(label: _topicLabel(l10n, question.topic)),
            Text(
              progressLabel,
              style: const TextStyle(
                color: AppColors.neonGold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: progressLabel,
          value: progressLabel,
          child: ExcludeSemantics(
            child: TzProgressBar(value: progress, height: 5),
          ),
        ),
        const SizedBox(height: 16),
        _RiverCard(
          key: const ValueKey('defense-target-river'),
          title: l10n.defenseTargetRiver(_seatLabel(l10n, question.targetSeat)),
          tileIds: question.targetDiscards,
          tilesById: tilesById,
          tileSemantics: (tileId) => l10n.defenseTileSemantics(
            _localizedTileName(l10n, tileId),
          ),
          highlighted: true,
        ),
        for (final river in otherRivers) ...[
          const SizedBox(height: 10),
          _RiverCard(
            key: ValueKey('defense-other-river-${river.key.name}'),
            title: l10n.defenseOtherRiver(_seatLabel(l10n, river.key)),
            tileIds: river.value,
            tilesById: tilesById,
            tileSemantics: (tileId) => l10n.defenseTileSemantics(
              _localizedTileName(l10n, tileId),
            ),
          ),
        ],
        if (question.additionalPublicVisibleCounts.isNotEmpty) ...[
          const SizedBox(height: 10),
          _VisibleTilesCard(
            counts: question.additionalPublicVisibleCounts,
            tilesById: tilesById,
            title: l10n.defenseAdditionalVisible,
            visibleCopies: l10n.defenseVisibleCopies,
            semanticsLabel: (tileId, count) => l10n.defenseVisibleTileSemantics(
              _localizedTileName(l10n, tileId),
              count,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.defenseQuestionPrompt,
          style: const TextStyle(
            color: AppColors.jadeWhite,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.defenseChoicesTitle,
          style: const TextStyle(
            color: AppColors.jadeWhiteMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
            final oneColumn = constraints.maxWidth < 330 || largeText;
            final itemWidth = oneColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
            final answer = _session.currentAnswer;
            return Wrap(
              key: const ValueKey('defense-choices'),
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final choice in question.choices)
                  SizedBox(
                    width: itemWidth,
                    child: _ChoiceCard(
                      choice: choice,
                      tile: tilesById[choice.tileId]!,
                      enabled: _session.phase == DefenseTrainingPhase.answering,
                      selected: answer?.selectedChoice.id == choice.id,
                      recommended:
                          _session.phase == DefenseTrainingPhase.revealed &&
                              question.bestChoiceId == choice.id,
                      semanticsLabel: l10n.defenseChooseTile(
                        _localizedTileName(l10n, choice.tileId),
                      ),
                      selectedLabel: l10n.defenseSelected,
                      recommendedLabel: l10n.defenseRecommended,
                      onPressed: () => _submit(choice.id),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_session.phase == DefenseTrainingPhase.revealed) ...[
          const SizedBox(height: 18),
          _FeedbackCard(
            answer: _session.currentAnswer!,
            tilesById: tilesById,
            l10n: l10n,
            isLast: _session.currentIndex + 1 == _session.totalCount,
            onNext: _next,
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(AppLocalizations l10n) {
    final accuracy = (_session.accuracy * 100).round();
    return ListView(
      key: const ValueKey('defense-summary-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 56,
          color: AppColors.neonGold,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.defenseSummaryTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.jadeWhite,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        TzCard(
          goldBorder: true,
          child: Column(
            children: [
              Text(
                l10n.defenseSummaryScore(
                  _session.correctCount,
                  _session.answeredCount,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.jadeWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.defenseSummaryAccuracy(accuracy),
                style: const TextStyle(
                  color: AppColors.neonGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.defenseSummaryBreakdown,
          style: const TextStyle(
            color: AppColors.jadeWhiteDim,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in _session.topicSummaries.entries) ...[
          TzCard(
            key: ValueKey('defense-summary-topic-${entry.key.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _topicLabel(l10n, entry.key),
                  style: const TextStyle(
                    color: AppColors.jadeWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.defenseSummaryTopicScore(
                    entry.value.correct,
                    entry.value.attempts,
                  ),
                  style: const TextStyle(
                    color: AppColors.neonGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        if (_session.isReview)
          TzButton(
            key: const ValueKey('defense-review-done'),
            label: l10n.defenseReviewDone,
            style: TzButtonStyle.gold,
            icon: Icons.check,
            onPressed: _done,
          )
        else ...[
          TzButton(
            key: const ValueKey('defense-try-again'),
            label: l10n.defenseTryAgain,
            style: TzButtonStyle.gold,
            icon: Icons.refresh,
            onPressed: _restart,
          ),
          const SizedBox(height: 10),
          TzButton(
            key: const ValueKey('defense-done'),
            label: l10n.defenseDone,
            style: TzButtonStyle.ghost,
            onPressed: _done,
          ),
        ],
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.celadonBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.celadonLight.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.celadonLight,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RiverCard extends StatelessWidget {
  const _RiverCard({
    super.key,
    required this.title,
    required this.tileIds,
    required this.tilesById,
    required this.tileSemantics,
    this.highlighted = false,
  });

  final String title;
  final List<String> tileIds;
  final Map<String, TileModel> tilesById;
  final String Function(String tileId) tileSemantics;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return TzCard(
      goldBorder: highlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: highlighted ? AppColors.neonGold : AppColors.jadeWhiteDim,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 7,
            children: [
              for (var index = 0; index < tileIds.length; index++)
                Semantics(
                  key: ValueKey('defense-river-tile-$index-${tileIds[index]}'),
                  image: true,
                  label: tileSemantics(tileIds[index]),
                  child: ExcludeSemantics(
                    child: TzTile(
                      tile: tilesById[tileIds[index]]!,
                      size: TileSize.sm,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisibleTilesCard extends StatelessWidget {
  const _VisibleTilesCard({
    required this.counts,
    required this.tilesById,
    required this.title,
    required this.visibleCopies,
    required this.semanticsLabel,
  });

  final Map<String, int> counts;
  final Map<String, TileModel> tilesById;
  final String title;
  final String Function(int count) visibleCopies;
  final String Function(String tile, int count) semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return TzCard(
      key: const ValueKey('defense-additional-visible'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.jadeWhiteDim,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final entry in entries)
                Semantics(
                  key: ValueKey('defense-visible-${entry.key}'),
                  label: semanticsLabel(entry.key, entry.value),
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TzTile(
                          tile: tilesById[entry.key]!,
                          size: TileSize.sm,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visibleCopies(entry.value),
                          style: const TextStyle(
                            color: AppColors.jadeWhiteMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choice,
    required this.tile,
    required this.enabled,
    required this.selected,
    required this.recommended,
    required this.semanticsLabel,
    required this.selectedLabel,
    required this.recommendedLabel,
    required this.onPressed,
  });

  final DefenseChoice choice;
  final TileModel tile;
  final bool enabled;
  final bool selected;
  final bool recommended;
  final String semanticsLabel;
  final String selectedLabel;
  final String recommendedLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderColor = recommended
        ? AppColors.neonGold
        : selected
            ? AppColors.celadonLight
            : AppColors.jadeHover;
    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('defense-choice-${choice.id}'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: borderColor.withValues(
                alpha: recommended || selected ? 0.12 : 0.04,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TzTile(tile: tile, size: TileSize.sm),
                  if (selected || recommended) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          if (selected)
                            _StatusBadge(
                              label: selectedLabel,
                              color: AppColors.celadonLight,
                            ),
                          if (recommended)
                            _StatusBadge(
                              label: recommendedLabel,
                              color: AppColors.neonGold,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.answer,
    required this.tilesById,
    required this.l10n,
    required this.isLast,
    required this.onNext,
  });

  final DefenseTrainingAnswer answer;
  final Map<String, TileModel> tilesById;
  final AppLocalizations l10n;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final accent =
        answer.isCorrect ? AppColors.celadonLight : AppColors.neonGold;
    return TzCard(
      key: const ValueKey('defense-feedback'),
      goldBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            answer.isCorrect
                ? Icons.check_circle_outline
                : Icons.lightbulb_outline,
            color: accent,
            size: 30,
          ),
          const SizedBox(height: 7),
          Text(
            answer.isCorrect
                ? l10n.defenseGoodDecision
                : l10n.defenseReviewChoice,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _FeedbackChoice(
            heading: l10n.defenseYourChoice,
            evidenceTitle: l10n.defenseEvidenceTitle,
            tileSemantics: l10n.defenseTileSemantics(
              _localizedTileName(l10n, answer.selectedChoice.tileId),
            ),
            choice: answer.selectedChoice,
            tile: tilesById[answer.selectedChoice.tileId]!,
            riskLabel: _riskLabel(l10n, answer.selectedChoice.riskLabel),
            explanation:
                _explanation(l10n, answer.selectedChoice.explanationCode),
          ),
          if (!answer.isCorrect) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.jadeHover.withValues(alpha: 0.9)),
            const SizedBox(height: 12),
            _FeedbackChoice(
              heading: l10n.defenseRecommendedChoice,
              evidenceTitle: l10n.defenseEvidenceTitle,
              tileSemantics: l10n.defenseTileSemantics(
                _localizedTileName(l10n, answer.bestChoice.tileId),
              ),
              choice: answer.bestChoice,
              tile: tilesById[answer.bestChoice.tileId]!,
              riskLabel: _riskLabel(l10n, answer.bestChoice.riskLabel),
              explanation:
                  _explanation(l10n, answer.bestChoice.explanationCode),
            ),
          ],
          const SizedBox(height: 18),
          TzButton(
            key: const ValueKey('defense-next'),
            label: isLast ? l10n.defenseViewSummary : l10n.defenseNext,
            style: TzButtonStyle.gold,
            icon: Icons.arrow_forward,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _FeedbackChoice extends StatelessWidget {
  const _FeedbackChoice({
    required this.heading,
    required this.evidenceTitle,
    required this.tileSemantics,
    required this.choice,
    required this.tile,
    required this.riskLabel,
    required this.explanation,
  });

  final String heading;
  final String evidenceTitle;
  final String tileSemantics;
  final DefenseChoice choice;
  final TileModel tile;
  final String riskLabel;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(choice.riskLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            color: AppColors.jadeWhiteMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              image: true,
              label: tileSemantics,
              child: ExcludeSemantics(
                child: TzTile(tile: tile, size: TileSize.sm),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evidenceTitle,
                    style: const TextStyle(
                      color: AppColors.jadeWhiteMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    riskLabel,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    explanation,
                    style: const TextStyle(
                      color: AppColors.jadeWhiteDim,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('defense-load-error-scroll'),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        const Icon(
          Icons.error_outline,
          color: AppColors.vermillion,
          size: 42,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.jadeWhiteDim,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        TzButton(
          key: const ValueKey('defense-retry'),
          label: retryLabel,
          style: TzButtonStyle.ghost,
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: 10),
          TzButton(
            key: const ValueKey('defense-error-done'),
            label: secondaryLabel!,
            style: TzButtonStyle.gold,
            icon: Icons.check_rounded,
            onPressed: onSecondary,
          ),
        ],
      ],
    );
  }
}

String _topicLabel(AppLocalizations l10n, DefenseTopic topic) =>
    switch (topic) {
      DefenseTopic.genbutsu => l10n.defenseTopicGenbutsu,
      DefenseTopic.suji => l10n.defenseTopicSuji,
      DefenseTopic.kabe => l10n.defenseTopicKabe,
      DefenseTopic.honorVisibility => l10n.defenseTopicHonorVisibility,
      DefenseTopic.combinedEvidence => l10n.defenseTopicCombinedEvidence,
    };

String _seatLabel(AppLocalizations l10n, DefenseSeat seat) => switch (seat) {
      DefenseSeat.east => l10n.defenseSeatEast,
      DefenseSeat.south => l10n.defenseSeatSouth,
      DefenseSeat.west => l10n.defenseSeatWest,
      DefenseSeat.north => l10n.defenseSeatNorth,
    };

String _localizedTileName(AppLocalizations l10n, String tileId) {
  if (tileId.length == 2) {
    final number = int.tryParse(tileId.substring(1));
    final suit = switch (tileId[0]) {
      'm' => l10n.defenseTileManSuit,
      'p' => l10n.defenseTilePinSuit,
      's' => l10n.defenseTileSouSuit,
      _ => null,
    };
    if (number != null && number >= 1 && number <= 9 && suit != null) {
      return l10n.defenseNumberedTile(number, suit);
    }
  }

  return switch (tileId) {
    'z1' => l10n.defenseTileEastWind,
    'z2' => l10n.defenseTileSouthWind,
    'z3' => l10n.defenseTileWestWind,
    'z4' => l10n.defenseTileNorthWind,
    'z5' => l10n.defenseTileRedDragon,
    'z6' => l10n.defenseTileGreenDragon,
    'z7' => l10n.defenseTileWhiteDragon,
    _ => throw ArgumentError.value(tileId, 'tileId', 'Unsupported tile ID'),
  };
}

String _riskLabel(AppLocalizations l10n, DefenseRiskLabel label) =>
    switch (label) {
      DefenseRiskLabel.absoluteAgainstTarget =>
        l10n.defenseRiskAbsoluteAgainstTarget,
      DefenseRiskLabel.stronglyReducedNotAbsolute =>
        l10n.defenseRiskStronglyReducedNotAbsolute,
      DefenseRiskLabel.relativelyReducedNotAbsolute =>
        l10n.defenseRiskRelativelyReducedNotAbsolute,
      DefenseRiskLabel.noEstablishedReduction =>
        l10n.defenseRiskNoEstablishedReduction,
    };

Color _riskColor(DefenseRiskLabel label) => switch (label) {
      DefenseRiskLabel.absoluteAgainstTarget => AppColors.suitSou,
      DefenseRiskLabel.stronglyReducedNotAbsolute => AppColors.celadonLight,
      DefenseRiskLabel.relativelyReducedNotAbsolute => AppColors.neonGold,
      DefenseRiskLabel.noEstablishedReduction => AppColors.jadeWhiteMuted,
    };

String _explanation(
  AppLocalizations l10n,
  DefenseExplanationCode code,
) =>
    switch (code) {
      DefenseExplanationCode.targetOwnDiscardIsGenbutsu =>
        l10n.defenseExplainTargetOwnDiscardIsGenbutsu,
      DefenseExplanationCode.otherOpponentDiscardIsNotTargetGenbutsu =>
        l10n.defenseExplainOtherOpponentDiscardIsNotTargetGenbutsu,
      DefenseExplanationCode.sujiCoversOnlyRyanmen =>
        l10n.defenseExplainSujiCoversOnlyRyanmen,
      DefenseExplanationCode.completeKabeStillNotAbsolute =>
        l10n.defenseExplainCompleteKabeStillNotAbsolute,
      DefenseExplanationCode.incompleteKabeLeavesSequencePossible =>
        l10n.defenseExplainIncompleteKabeLeavesSequencePossible,
      DefenseExplanationCode.threeVisibleHonorHasKokushiException =>
        l10n.defenseExplainThreeVisibleHonorHasKokushiException,
      DefenseExplanationCode.twoVisibleHonorStillNotSafe =>
        l10n.defenseExplainTwoVisibleHonorStillNotSafe,
      DefenseExplanationCode.combinedSujiAndKabeStillNotAbsolute =>
        l10n.defenseExplainCombinedSujiAndKabeStillNotAbsolute,
      DefenseExplanationCode.targetGenbutsuOutranksRelativeClues =>
        l10n.defenseExplainTargetGenbutsuOutranksRelativeClues,
      DefenseExplanationCode.noEstablishedSafetyEvidence =>
        l10n.defenseExplainNoEstablishedSafetyEvidence,
    };
