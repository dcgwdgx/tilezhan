import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Learning', [
            _tile(Icons.speed, 'Animation Speed', 'Normal'),
            _tile(Icons.flag, 'Daily Goal', '10 cards'),
            _tile(Icons.timer, 'Countdown', '8 seconds'),
          ]),
          const SizedBox(height: 24),
          _section('Account', [
            _tile(Icons.person_outline, 'Sign In', 'Coming soon'),
            _tile(Icons.restore, 'Restore Purchases', 'Coming soon'),
          ]),
          const SizedBox(height: 24),
          _section('About', [
            _tile(Icons.info_outline, 'Version', '1.0.0+1'),
            _tile(Icons.shield_outlined, 'Privacy Policy', ''),
            _tile(Icons.description_outlined, 'Terms of Service', ''),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.jadeWhiteMuted)),
      ),
      Container(
        decoration: BoxDecoration(color: AppColors.jadeCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.jadeHover)),
        child: Column(children: tiles),
      ),
    ],
  );

  Widget _tile(IconData icon, String title, String subtitle) => ListTile(
    leading: Icon(icon, color: AppColors.neonGold, size: 22),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite)),
    subtitle: subtitle.isEmpty ? null : Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
