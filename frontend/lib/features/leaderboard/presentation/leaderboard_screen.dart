/// Global ELO leaderboard — ranks players by skill score.
///
/// Fetches top 50 from backend [/api/v1/leaderboard], displays ranked
/// list with gold top-3 highlighting, highlights current player's row,
/// and shows a "My Rank" section at the bottom. First-time visitors
/// are prompted to enter a display name via a bottom sheet.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/elo/elo_provider.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/providers/player_name_provider.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/storage/storage_service.dart';
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
    // Show name entry on first visit if player hasn't set a name yet.
    Future.microtask(() => _maybeShowNameEntry());
  }

  /// Prompt for display name if it hasn't been set yet.
  void _maybeShowNameEntry() {
    final name = ref.read(playerNameProvider);
    if (name.isEmpty) {
      _showNameEntrySheet();
    }
  }

  /// Fetch top-50 leaderboard from backend.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playerName = ref.watch(playerNameProvider);
    final elo = ref.watch(eloProvider);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop()),
        title: Text(l10n.leaderboardTitle, style: const TextStyle(color: AppColors.jadeWhite)),
      ),
      body: _buildBody(l10n, playerName, elo),
    );
  }

  /// State-machine body: loading spinner → error + retry → empty CTA → ranked list + My Rank.
  Widget _buildBody(AppLocalizations l10n, String playerName, int elo) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonGold));
    }

    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: AppColors.jadeWhiteDim)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _fetch,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGold),
          child: Text(l10n.leaderboardRetry, style: const TextStyle(color: Colors.black))),
      ]));
    }

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

    // Find current player in rankings for highlighting.
    final myEntry = playerName.isNotEmpty
        ? _rankings!.cast<Map<String, dynamic>?>().firstWhere(
            (r) => r?['name'] == playerName,
            orElse: () => null,
          )
        : null;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _rankings!.length + 1, // +1 for My Rank footer
      itemBuilder: (_, i) {
        // Last item = My Rank section
        if (i == _rankings!.length) {
          return _buildMyRank(l10n, playerName, elo);
        }

        final r = _rankings![i];
        final rank = r['rank'] ?? i + 1;
        final isTop3 = rank <= 3;
        final isMe = playerName.isNotEmpty && r['name'] == playerName;
        final medals = ['🥇', '🥈', '🥉'];

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.neonGold.withOpacity(0.12)
                : (isTop3 ? AppColors.neonGold.withOpacity(0.08) : AppColors.jadeCard),
            borderRadius: BorderRadius.circular(12),
            border: isMe
                ? Border.all(color: AppColors.neonGold.withOpacity(0.4), width: 1.5)
                : (isTop3 ? Border.all(color: AppColors.neonGold.withOpacity(0.2)) : null),
          ),
          child: Row(children: [
            // Rank badge
            SizedBox(width: 30, child: Text(
              isTop3 ? medals[rank - 1] : '#$rank',
              style: TextStyle(fontSize: isTop3 ? 20 : 14, color: AppColors.jadeWhite),
            )),
            const SizedBox(width: 12),
            // Name + streak + "YOU" badge
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(r['name'] ?? 'Anonymous',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isMe ? AppColors.neonGold : AppColors.jadeWhite))),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.neonGold.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(l10n.leaderboardYou, style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.neonGold)),
                  ),
                ],
              ]),
              Text(l10n.leaderboardStreak('${r['streak'] ?? 0}'),
                style: const TextStyle(fontSize: 11, color: AppColors.jadeWhiteDim)),
            ])),
            // ELO score
            Text(l10n.leaderboardElo('${r['elo'] ?? 800}'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: isMe ? AppColors.neonGold : AppColors.neonGold)),
          ]),
        );
      },
    );
  }

  /// "My Rank" section shown at the bottom of the leaderboard.
  ///
  /// If the player has set a name and is not in the top 50, shows their
  /// stats separately. If no name is set, shows a CTA to play games.
  Widget _buildMyRank(AppLocalizations l10n, String playerName, int elo) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.jadeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGold.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(l10n.leaderboardMyRank,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: AppColors.neonGold)),
        const SizedBox(height: 12),
        if (playerName.isNotEmpty) ...[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person, color: AppColors.jadeWhiteDim, size: 20),
            const SizedBox(width: 8),
            Text(playerName, style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700, color: AppColors.jadeWhite)),
          ]),
          const SizedBox(height: 6),
          Text(l10n.leaderboardElo('$elo'), style: const TextStyle(fontSize: 20,
            fontWeight: FontWeight.w900, color: AppColors.neonGold)),
          const SizedBox(height: 6),
          Text(l10n.leaderboardKeepPlaying,
            style: const TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
          if (playerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showNameEntrySheet,
              child: Text(l10n.leaderboardChangeName,
                style: TextStyle(fontSize: 11, color: AppColors.neonGold.withOpacity(0.7))),
            ),
          ],
        ] else ...[
          Text(l10n.leaderboardNotRanked,
            style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
        ],
      ]),
    );
  }

  /// Show a bottom sheet for entering / changing the player display name.
  void _showNameEntrySheet() {
    final controller = TextEditingController(text: ref.read(playerNameProvider));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.jadeCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.leaderboardEnterName, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jadeWhite)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              style: const TextStyle(color: AppColors.jadeWhite),
              decoration: InputDecoration(
                hintText: l10n.leaderboardNameHint,
                hintStyle: const TextStyle(color: AppColors.jadeWhiteMuted),
                filled: true,
                fillColor: AppColors.jadeDeep,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: AppColors.jadeWhiteMuted),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final storage = ref.read(storageServiceProvider).valueOrNull;
                  await storage?.setString('player_name', name);
                  ref.invalidate(playerNameProvider);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.leaderboardSaveName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            )),
          ]),
        );
      },
    );
  }
}
