import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_button.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../data/hand_analysis_history_store.dart';
import '../domain/hand_analysis_history.dart';
import '../domain/hand_analyzer.dart';
import 'hand_analysis_result_panel.dart';
import 'hand_analyzer_tile_adapter.dart';

/// Called after the user requests analysis of a valid 13- or 14-tile hand.
typedef HandAnalyzerAnalyzeCallback = void Function(List<String> tileIds);

/// Optional seam through which the domain-backed result UI can be attached.
typedef HandAnalyzerResultBuilder = Widget Function(
  BuildContext context,
  List<String> tileIds,
);

/// Manual hand-entry UI, intentionally isolated from the analysis engine.
///
/// The screen owns only physical tile selection. The route can inject
/// [onAnalyze] and [resultBuilder] once the domain API is connected, without
/// changing the picker or duplicating its validation rules.
class HandAnalyzerScreen extends ConsumerStatefulWidget {
  const HandAnalyzerScreen({
    super.key,
    this.initialTileIds = const <String>[],
    this.onHandChanged,
    this.onAnalyze,
    this.resultBuilder,
    this.historyStore,
  });

  final List<String> initialTileIds;
  final ValueChanged<List<String>>? onHandChanged;
  final HandAnalyzerAnalyzeCallback? onAnalyze;
  final HandAnalyzerResultBuilder? resultBuilder;
  final HandAnalysisHistoryStore? historyStore;

  @override
  ConsumerState<HandAnalyzerScreen> createState() =>
      _HandAnalyzerScreenState();
}

class _HandAnalyzerScreenState extends ConsumerState<HandAnalyzerScreen> {
  late HandAnalyzerSelection _selection;
  late final Future<HandAnalysisHistoryStore> _historyStore;
  late final Future<void> _historyLoad;
  final GlobalKey _resultKey = GlobalKey();
  Future<void> _historyWrite = Future<void>.value();
  bool _showResult = false;
  HandAnalysis? _analysis;
  HandAnalysisHistory _history = HandAnalysisHistory.empty();

  @override
  void initState() {
    super.initState();
    _selection = HandAnalyzerSelection.fromTileIds(widget.initialTileIds);
    _historyStore = widget.historyStore == null
        ? _createHistoryStore()
        : Future<HandAnalysisHistoryStore>.value(widget.historyStore);
    _historyLoad = _loadHistory();
    unawaited(_historyLoad);
  }

  Future<HandAnalysisHistoryStore> _createHistoryStore() async {
    final storage = await ref.read(storageServiceProvider.future);
    return StorageServiceHandAnalysisHistoryStore(storage);
  }

  Future<void> _loadHistory() async {
    try {
      final store = await _historyStore;
      final history = store.read();
      if (!mounted) return;
      setState(() => _history = history);
    } on Object {
      // Analysis remains fully usable when device-local history is unavailable.
    }
  }

  void _publishSelection(HandAnalyzerSelection next) {
    setState(() {
      _selection = next;
      _showResult = false;
      _analysis = null;
    });
    widget.onHandChanged?.call(next.tileIds);
  }

  void _addTile(String tileId) {
    final l10n = AppLocalizations.of(context)!;
    final update = _selection.add(tileId);
    if (update.added) {
      _publishSelection(update.selection);
      return;
    }

    final message = switch (update.issue) {
      HandAnalyzerSelectionIssue.fourCopyLimit =>
        l10n.handAnalyzerFourCopyLimit,
      HandAnalyzerSelectionIssue.unsupportedTile => l10n.handAnalyzerError,
      HandAnalyzerSelectionIssue.handFull => null,
      null => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _removeTile(int index) {
    _publishSelection(_selection.removeAt(index));
  }

  void _clear() {
    if (_selection.count == 0) return;
    _publishSelection(_selection.clear());
  }

  void _analyze() {
    if (!_selection.canAnalyze) return;
    final tileIds = List<String>.unmodifiable(_selection.tileIds);
    try {
      final analysis = HandAnalyzer.analyze(tileIds);
      setState(() {
        _analysis = analysis;
        _showResult = true;
      });
      widget.onAnalyze?.call(tileIds);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final resultContext = _resultKey.currentContext;
        if (resultContext != null) {
          Scrollable.ensureVisible(
            resultContext,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: 0.08,
          );
        }
      });
    } on Object {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.handAnalyzerError)));
    }
  }

  Future<void> _saveAnalysis() async {
    final analysis = _analysis;
    if (analysis == null) return;
    // Merge with disk state before applying the first mutation. This prevents a
    // fast tap during storage initialization from overwriting older records.
    await _historyLoad;
    if (!mounted) return;
    final next = _history.recordAnalysis(
      tileIds: analysis.handTiles,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _history = next);
    await _persistHistory(next);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.handAnalyzerSaved)));
  }

  Future<void> _persistHistory(HandAnalysisHistory snapshot) {
    _historyWrite = _historyWrite.catchError((_) {}).then((_) async {
      final store = await _historyStore;
      await store.write(snapshot);
    });
    return _historyWrite;
  }

  void _openHistory(HandAnalysisRecord record) {
    try {
      final selection = HandAnalyzerSelection.fromTileIds(record.tileIds);
      final analysis = HandAnalyzer.analyze(selection.tileIds);
      setState(() {
        _selection = selection;
        _analysis = analysis;
        _showResult = true;
      });
      widget.onHandChanged?.call(selection.tileIds);
      widget.onAnalyze?.call(selection.tileIds);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final resultContext = _resultKey.currentContext;
        if (resultContext != null) {
          Scrollable.ensureVisible(
            resultContext,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: 0.08,
          );
        }
      });
    } on Object {
      // Persisted records are validated on read; this is a final safety net for
      // future engine rule changes.
    }
  }

  void _deleteHistory(HandAnalysisRecord record) {
    final next = _history.remove(record.id);
    setState(() => _history = next);
    unawaited(_persistHistory(next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tileData = ref.watch(tileDataProvider);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        title: Text(
          l10n.handAnalyzerTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: tileData.when(
          data: (tiles) => _buildLoaded(context, tiles),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonGold),
          ),
          error: (_, __) => _LoadError(
            message: l10n.handAnalyzerError,
            onRetry: () => ref.invalidate(tileDataProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<TileModel> tiles) {
    final l10n = AppLocalizations.of(context)!;
    final byId = {for (final tile in tiles) tile.id: tile};
    if (HandAnalyzerTileCatalog.allTileIds.any((id) => !byId.containsKey(id))) {
      return _LoadError(
        message: l10n.handAnalyzerError,
        onRetry: () => ref.invalidate(tileDataProvider),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntroCard(
            title: l10n.handAnalyzerSubtitle,
            scope: l10n.handAnalyzerScope,
          ),
          const SizedBox(height: 16),
          _Panel(
            key: const ValueKey('hand-analyzer-hand'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.handAnalyzerHand,
                      style: const TextStyle(
                        color: AppColors.jadeWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _CountPill(
                        label: l10n.handAnalyzerTileCount(
                          _selection.count,
                          _selection.targetCount,
                        ),
                        ready: _selection.canAnalyze,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selection.tileIds.isEmpty)
                  _EmptyHand(message: l10n.handAnalyzerNeedTileCount)
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (var index = 0;
                          index < _selection.tileIds.length;
                          index++)
                        TzTile(
                          key: ValueKey(
                            'hand-analyzer-selected-$index-'
                            '${_selection.tileIds[index]}',
                          ),
                          tile: byId[_selection.tileIds[index]]!,
                          size: TileSize.sm,
                          onTap: () => _removeTile(index),
                        ),
                    ],
                  ),
                const SizedBox(height: 10),
                Text(
                  _selection.canAnalyze
                      ? l10n.handAnalyzerRemoveHint
                      : l10n.handAnalyzerNeedTileCount,
                  style: const TextStyle(
                    color: AppColors.jadeWhiteMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    key: const ValueKey('hand-analyzer-clear'),
                    onPressed: _selection.count == 0 ? null : _clear,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: Text(l10n.handAnalyzerClear),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.jadeWhiteDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            key: const ValueKey('hand-analyzer-picker'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.handAnalyzerPicker,
                  style: const TextStyle(
                    color: AppColors.jadeWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _TilePickerGroup(
                  label: l10n.handAnalyzerMan,
                  tileIds: HandAnalyzerTileCatalog.manTileIds,
                  tilesById: byId,
                  selection: _selection,
                  onTilePressed: _addTile,
                ),
                _TilePickerGroup(
                  label: l10n.handAnalyzerPin,
                  tileIds: HandAnalyzerTileCatalog.pinTileIds,
                  tilesById: byId,
                  selection: _selection,
                  onTilePressed: _addTile,
                ),
                _TilePickerGroup(
                  label: l10n.handAnalyzerSou,
                  tileIds: HandAnalyzerTileCatalog.souTileIds,
                  tilesById: byId,
                  selection: _selection,
                  onTilePressed: _addTile,
                ),
                _TilePickerGroup(
                  label: l10n.handAnalyzerHonors,
                  tileIds: HandAnalyzerTileCatalog.honorTileIds,
                  tilesById: byId,
                  selection: _selection,
                  onTilePressed: _addTile,
                  showBottomSpacing: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TzButton(
            key: const ValueKey('hand-analyzer-analyze'),
            label: l10n.handAnalyzerAnalyze,
            icon: Icons.analytics_outlined,
            style: TzButtonStyle.gold,
            onPressed: _selection.canAnalyze ? _analyze : null,
          ),
          if (_showResult && _analysis != null) ...[
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _resultKey,
              child: widget.resultBuilder?.call(context, _selection.tileIds) ??
                  HandAnalysisResultPanel(
                    analysis: _analysis!,
                    tilesById: byId,
                    onSave: _saveAnalysis,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          HandAnalysisHistoryPanel(
            records: _history.recent,
            tilesById: byId,
            onOpen: _openHistory,
            onDelete: _deleteHistory,
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.title, required this.scope});

  final String title;
  final String scope;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.jadeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.neonGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_customize_outlined,
              color: AppColors.neonGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.jadeWhite,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scope,
                  style: const TextStyle(
                    color: AppColors.jadeWhiteDim,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.jadeCard.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.jadeHover),
      ),
      child: child,
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.neonGold : AppColors.jadeWhiteMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyHand extends StatelessWidget {
  const _EmptyHand({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.jadeDeep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.jadeHover),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.jadeWhiteMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TilePickerGroup extends StatelessWidget {
  const _TilePickerGroup({
    required this.label,
    required this.tileIds,
    required this.tilesById,
    required this.selection,
    required this.onTilePressed,
    this.showBottomSpacing = true,
  });

  final String label;
  final List<String> tileIds;
  final Map<String, TileModel> tilesById;
  final HandAnalyzerSelection selection;
  final ValueChanged<String> onTilePressed;
  final bool showBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: showBottomSpacing ? 18 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.jadeWhiteDim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 9,
            children: [
              for (final tileId in tileIds)
                _PickerTile(
                  key: ValueKey('hand-analyzer-picker-$tileId'),
                  tile: tilesById[tileId]!,
                  selectedCount: selection.copiesOf(tileId),
                  handFull: selection.isFull,
                  onPressed: () => onTilePressed(tileId),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    super.key,
    required this.tile,
    required this.selectedCount,
    required this.handFull,
    required this.onPressed,
  });

  final TileModel tile;
  final int selectedCount;
  final bool handFull;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reachedCopyLimit =
        selectedCount >= HandAnalyzerSelection.maximumCopiesPerTile;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TzTile(
          tile: tile,
          size: TileSize.sm,
          state: handFull || reachedCopyLimit
              ? TileState.dimmed
              : TileState.normal,
          onTap: handFull ? null : onPressed,
        ),
        if (selectedCount > 0)
          PositionedDirectional(
            top: -5,
            end: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: reachedCopyLimit
                    ? AppColors.vermillion
                    : AppColors.neonGold,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.jadeDeep, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$selectedCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.vermillion,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.jadeWhiteDim),
            ),
            const SizedBox(height: 8),
            IconButton(
              tooltip: message,
              onPressed: onRetry,
              color: AppColors.neonGold,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
