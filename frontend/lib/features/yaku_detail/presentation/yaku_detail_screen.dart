/// Yaku detail screen — tile layouts, conditions, han, combos, and tips.
///
/// Receives a yaku [id] via route parameter and displays the full
/// yaku info card with expandable conditions and combo suggestions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/yaku_data.dart';
import '../domain/yaku_favorites_provider.dart';

/// Full-screen detail card for a single yaku, rendered as five scrollable
/// card sections: basic info, conditions, example hand, common combos, and
/// a pro tip. Favorites toggle persisted via [yakuFavoritesProvider].
class YakuDetailScreen extends ConsumerWidget {
  /// The route-parameter yaku identifier used to look up data from [staticYakuList].
  final String yakuId;

  const YakuDetailScreen({super.key, required this.yakuId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaku = getYakuById(yakuId);
    final favorites = ref.watch(yakuFavoritesProvider);
    final isFavorite = favorites.contains(yakuId);
    if (yaku == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: AppColors.jadeDeep,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.commonNotFound, style: const TextStyle(color: AppColors.jadeWhiteDim)),
          TextButton(onPressed: () => context.pop(), child: Text(l10n.commonGoBack)),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        title: Text(yaku.nameEn, style: const TextStyle(color: AppColors.jadeWhite)),
        actions: [
          // ⭐ Favorites toggle — persisted to Hive via yakuFavoritesProvider
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: AppColors.neonGold,
            ),
            onPressed: () => ref.read(yakuFavoritesProvider.notifier).toggle(yakuId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          /// Section 1 — Basic info: name, Japanese name badge, han count,
          /// difficulty tag, and a short prose description.
          _card([
            Row(children: [
              Expanded(child: Text(yaku.nameEn, style: const TextStyle(fontSize: 24,
                fontWeight: FontWeight.w900, color: AppColors.jadeWhite))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.neonGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
                child: Text(yaku.nameJp, style: const TextStyle(fontSize: 13,
                  color: AppColors.neonGold))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _tag('${yaku.han} Han${yaku.hanClosed != yaku.han ? ' (${yaku.hanClosed} closed)' : ''}'),
              const SizedBox(width: 8),
              _tag(yaku.difficulty),
            ]),
            const SizedBox(height: 12),
            Text(yaku.description, style: const TextStyle(fontSize: 14,
              color: AppColors.jadeWhiteDim, height: 1.6)),
          ]),
          const SizedBox(height: 16),

          /// Section 2 — Conditions: checklist of must-have and must-not-have
          /// requirements, each prefixed with ✅ or ❌ for quick scanning.
          _sectionTitle('Conditions'),
          _card(yaku.conditions.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.startsWith('Must not') || c.startsWith('Cannot') || c.startsWith('No')
                ? '❌' : '✅', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Expanded(child: Text(c, style: const TextStyle(fontSize: 14,
                color: AppColors.jadeWhite, height: 1.5))),
            ]),
          )).toList()),
          const SizedBox(height: 16),

          /// Section 3 — Example: one or more tile-layout strings showing
          /// what a winning hand with this yaku looks like.
          _sectionTitle('Example'),
          _card(yaku.examples.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(e, style: const TextStyle(fontSize: 16,
              color: AppColors.jadeWhite, height: 1.6)),
          )).toList()),
          const SizedBox(height: 16),

          /// Section 4 — Common combinations: yaku that frequently appear
          /// together with this one, each showing the combined han total.
          _sectionTitle('Common Combinations'),
          _card(yaku.combos.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(child: Text(c.name, style: const TextStyle(fontSize: 14,
                color: AppColors.jadeWhite))),
              Text('${c.totalHan} Han', style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: AppColors.neonGold)),
            ]),
          )).toList()),
          const SizedBox(height: 16),

          /// Section 5 — Pro tip: a single actionable piece of strategy advice
          /// (prefixed with 💡) to help the player pursue or avoid this yaku.
          _sectionTitle('Pro Tip'),
          _card([Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(yaku.tip, style: const TextStyle(fontSize: 14,
              color: AppColors.jadeWhiteDim, height: 1.6))),
          ])]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  /// Renders a gold, uppercase section heading with letter-spacing,
  /// used to label each of the five info cards.
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 12,
        fontWeight: FontWeight.w700, letterSpacing: 1.5,
        color: AppColors.neonGold)),
    );
  }

  /// Wraps [children] in a full-width rounded container with the
  /// standard card background, border, and 16 px inner padding.
  Widget _card(List<Widget> children) {
    return Container(width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.jadeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.jadeHover),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  /// Returns a small rounded pill label for han counts and difficulty
  /// badges, styled with a muted background consistent with the theme.
  Widget _tag(String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: AppColors.jadeHover,
        borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)));
  }
}
