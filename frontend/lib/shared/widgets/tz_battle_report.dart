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
import '../widgets/tz_button.dart';

class TzBattleReport extends ConsumerStatefulWidget {
  const TzBattleReport({super.key});

  @override
  ConsumerState<TzBattleReport> createState() => _TzBattleReportState();
}

class _TzBattleReportState extends ConsumerState<TzBattleReport> {
  /// Share results as text via system share sheet.
  Future<void> _shareResults(BattleReport report) async {
    final text = '🎯 ${report.total} puzzles today · '
        '${(report.accuracy * 100).toInt()}% accuracy · '
        '${report.maxCombo}× max combo on TileZhan! tilezhan.app';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
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
              const Text('Today\'s Battle Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.neonGold)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _stat('Total', '${report.total}'),
                _stat('Accuracy', '${(report.accuracy * 100).toInt()}%'),
                _stat('Max Combo', '${report.maxCombo}×'),
              ]),
              const SizedBox(height: 12),
              Text('tilezhan.app',
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
                const Text('COMBO ×10!', style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w800, color: AppColors.neonGold)),
                const Text('Annual 20% OFF — \$23.99/yr',
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
                  child: const Text('UNLOCK', style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
            ]),
          ),
        // Action buttons
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _actionBtn(Icons.share, 'Share', () => _shareResults(report)),
          const SizedBox(width: 24),
          _actionBtn(Icons.auto_fix_high, 'Mistakes', () {
            Navigator.pop(context);
            context.push('/graveyard');
          }),
          const SizedBox(width: 24),
          _actionBtn(Icons.person_add, 'Invite', () {
            _shareInviteLink();
          }),
        ]),
        const SizedBox(height: 16),

        // Premium CTA
        TzButton(
          label: '\$4.99/mo  —  Unlimited Play',
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
    Share.share(
      '🀄 Join me on TileZhan — master Mahjong tile recognition! '
      'Free daily puzzles. Get it at tilezhan.app',
    );
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
