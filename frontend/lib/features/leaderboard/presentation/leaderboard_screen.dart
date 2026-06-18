/// Global ELO leaderboard — ranks players by skill score.
///
/// Fetches top 100 from backend [/api/v1/leaderboard] and displays
/// rank, name, ELO, and streak. Personal rank is highlighted.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../l10n/generated/app_localizations.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  List<Map<String, dynamic>>? _rankings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// Fetch top-50 leaderboard from backend.
  ///
  /// Resets loading/error state on each call. On success, decodes the
  /// JSON response and stores the rankings list. On failure, sets a
  /// user-facing error message so [_buildBody] can show a retry button.
  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/leaderboard/?limit=50'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _rankings = List<Map<String, dynamic>>.from(data['rankings'] ?? []);
          _loading = false;
        });
      } else {
        setState(() { _error = 'Server error (${res.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Unable to load rankings'; _loading = false; });
    }
  }

  /// Scaffold with jade-themed AppBar + state-driven body.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop()),
        title: Text(l10n.leaderboardTitle, style: const TextStyle(color: AppColors.jadeWhite)),
      ),
      body: _buildBody(l10n),
    );
  }

  /// State-machine body: loading spinner → error + retry → empty CTA → ranked list.
  Widget _buildBody(AppLocalizations l10n) {
    // --- Loading state ---
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonGold));
    }

    // --- Error state with retry ---
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _fetch,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGold),
          child: Text(l10n.leaderboardRetry, style: const TextStyle(color: Colors.black))),
      ]));
    }

    // --- Empty state: no rankings yet ---
    if (_rankings == null || _rankings!.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏆', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(l10n.leaderboardEmpty,
          style: const TextStyle(fontSize: 16, color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 4),
        Text(l10n.leaderboardEmptySub,
          style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteMuted)),
      ]));
    }

    // --- Ranked list ---
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankings!.length,
      itemBuilder: (_, i) {
        final r = _rankings![i];
        // Fall back to 1-based index if 'rank' field is missing.
        final rank = r['rank'] ?? i + 1;
        final isTop3 = rank <= 3;
        final medals = ['🥇', '🥈', '🥉'];

        // --- Ranking card: gold-tinted for top 3, standard card otherwise ---
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isTop3 ? AppColors.neonGold.withOpacity(0.08) : AppColors.jadeCard,
            borderRadius: BorderRadius.circular(12),
            border: isTop3 ? Border.all(color: AppColors.neonGold.withOpacity(0.2)) : null,
          ),
          child: Row(children: [
            // Rank badge — medal emoji for top 3, hash-prefixed number otherwise.
            SizedBox(width: 30, child: Text(
              isTop3 ? medals[rank - 1] : '#$rank',
              style: TextStyle(fontSize: isTop3 ? 20 : 14, color: AppColors.jadeWhite),
            )),
            const SizedBox(width: 12),
            // Player name + streak.
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['name'] ?? 'Anonymous',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite)),
              Text('${r['streak'] ?? 0} streak',
                style: const TextStyle(fontSize: 11, color: AppColors.jadeWhiteDim)),
            ])),
            // ELO score — gold, bold.
            Text('${r['elo'] ?? 800} ELO',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.neonGold)),
          ]),
        );
      },
    );
  }
}
