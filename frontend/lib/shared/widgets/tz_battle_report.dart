/// Battle report modal — shown when free user runs out of hearts.
///
/// Displays session stats (accuracy, combo, total) with premium CTA,
/// mistake review link, and a share button to post results on social media.
/// Premium users never see this.
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/hearts/heart_provider.dart';
import '../widgets/tz_button.dart';

class TzBattleReport extends ConsumerStatefulWidget {
  const TzBattleReport({super.key});

  @override
  ConsumerState<TzBattleReport> createState() => _TzBattleReportState();
}

class _TzBattleReportState extends ConsumerState<TzBattleReport> {
  final _captureKey = GlobalKey();

  /// Capture the battle report card as a PNG and share it.
  Future<void> _shareResults(BattleReport report) async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/tilezhan_report_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🎯 ${report.total} puzzles today · '
            '${(report.accuracy * 100).toInt()}% accuracy · '
            '${report.maxCombo}× max combo on TileZhan!',
      );
    } catch (e) {
      // Share failed — non-critical
    }
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
        RepaintBoundary(
          key: _captureKey,
          child: Container(
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
        ),
        const SizedBox(height: 16),

        // Share button
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
