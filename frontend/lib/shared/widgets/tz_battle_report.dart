/// Battle report modal — shown when free user runs out of hearts.
///
/// Displays session stats (accuracy, combo, total) with premium CTA,
/// mistake review link, and a share button to post results on social media.
/// Premium users never see this.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/hearts/heart_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/tz_button.dart';

class TzBattleReport extends ConsumerStatefulWidget {
  const TzBattleReport({super.key});

  @override
  ConsumerState<TzBattleReport> createState() => _TzBattleReportState();
}

class _TzBattleReportState extends ConsumerState<TzBattleReport> {
  /// Share results as text via system share sheet.
  /// Closes modal first — share_plus fails when called from inside a modal on iOS.
  Future<void> _shareResults(BattleReport report) async {
    final text = '🎯 ${report.total} puzzles today · '
        '${(report.accuracy * 100).toInt()}% accuracy · '
        '${report.maxCombo}× max combo on TileZhan! tilezhan.app';
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final report = ref.watch(battleReportProvider);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.jadeDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, decoration: BoxDecoration(
          color: AppColors.jadeWhiteMuted.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(height: 20),

        // Sharable card (captured as image)
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3526), Color(0xFF0D3D26)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonGold.withOpacity(0.2)),
            ),
            child: Column(children: [
              const Text('🎯', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text(l10n.battleTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.neonGold)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _stat(l10n.battleTotal, '${report.total}'),
                _stat(l10n.battleAccuracy, '${(report.accuracy * 100).toInt()}%'),
                _stat(l10n.battleMaxCombo, '${report.maxCombo}×'),
              ]),
              const SizedBox(height: 12),
              Text(l10n.battleDomain,
                style: TextStyle(fontSize: 11, color: AppColors.neonGold.withOpacity(0.6))),
            ]),
          ),
        const SizedBox(height: 16),

        // Combo promo banner (10+ streak → discount)
        if (ref.watch(showComboPromoProvider))
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.battleComboBanner, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w800, color: AppColors.neonGold)),
                Text(l10n.battleComboSub,
                  style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
              ])),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/premium');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l10n.battleComboUnlock, style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
            ]),
          ),
        // Action buttons
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _actionBtn(Icons.share, l10n.battleShare, () => _shareResults(report)),
          const SizedBox(width: 24),
          _actionBtn(Icons.auto_fix_high, l10n.battleMistakesBtn, () {
            Navigator.pop(context);
            context.push('/graveyard');
          }),
          const SizedBox(width: 24),
          _actionBtn(Icons.person_add, l10n.battleInvite, () {
            _shareInviteLink();
          }),
        ]),
        const SizedBox(height: 16),

        // Premium CTA
        TzButton(
          label: l10n.battlePremiumCTA,
          style: TzButtonStyle.gold,
          onPressed: () => context.push('/premium'),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.jadeCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.jadeHover),
          ),
          child: Icon(icon, color: AppColors.jadeWhiteDim, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.jadeWhiteMuted)),
      ]),
    );
  }

  void _shareInviteLink() {
    final text = '🀄 Join me on TileZhan — master Mahjong tile recognition! '
        'Free daily puzzles. Get it at tilezhan.app';
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) Share.share(text);
    });
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 24,
        fontWeight: FontWeight.w900, color: AppColors.jadeWhite)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11,
        color: AppColors.jadeWhiteMuted)),
    ]);
  }
}
