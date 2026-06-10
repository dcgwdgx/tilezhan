import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/animation_speed_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(animationSpeedProvider);

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
          _buildSection('Learning', [
            _buildSpeedTile(context, ref, speed),
            const _GrayTile(title: 'Daily Goal', subtitle: '10 cards', icon: Icons.flag),
          ]),
          const SizedBox(height: 24),
          _buildSection('Account', [
            const _GrayTile(title: 'Sign In', subtitle: 'Coming soon', icon: Icons.person_outline),
            const _GrayTile(title: 'Restore Purchases', subtitle: 'Coming soon', icon: Icons.restore),
          ]),
          const SizedBox(height: 24),
          _buildSection('About', [
            _buildAboutTile(context),
            const _GrayTile(title: 'Privacy Policy', subtitle: '', icon: Icons.shield_outlined),
            const _GrayTile(title: 'Terms of Service', subtitle: '', icon: Icons.description_outlined),
          ]),
          const SizedBox(height: 24),
          _buildSection('Data', [
            const _GrayTile(title: 'Clear Local Data', subtitle: '', icon: Icons.delete_outline),
            const _GrayTile(title: 'Export Wrong Answers', subtitle: 'Coming soon', icon: Icons.file_download_outlined),
          ]),
          const SizedBox(height: 40),
          const Center(
            child: Text('TileSlash v1.0.0+1', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
            color: AppColors.jadeWhiteMuted,
          )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.jadeCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.jadeHover),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSpeedTile(BuildContext context, WidgetRef ref, double speed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.speed, color: AppColors.neonGold, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Animation Speed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite)),
                SizedBox(height: 2),
                Text('Adjust visual feedback speed', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
              ],
            ),
          ),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 1.0, label: Text('Full', style: TextStyle(fontSize: 10))),
              ButtonSegment(value: 0.2, label: Text('Fast', style: TextStyle(fontSize: 10))),
              ButtonSegment(value: 0.0, label: Text('Off', style: TextStyle(fontSize: 10))),
            ],
            selected: {speed},
            onSelectionChanged: (v) => ref.read(animationSpeedProvider.notifier).state = v.first,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.neonGold.withOpacity(0.2);
                return AppColors.jadeDeep;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.neonGold;
                return AppColors.jadeWhiteMuted;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: AppColors.celadonBlue, size: 22),
      title: const Text('Version', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite)),
      subtitle: const Text('1.0.0+1', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

/// Grayed-out tile for not-yet-implemented features.
class _GrayTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _GrayTile({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.jadeWhiteMuted.withOpacity(0.4), size: 22),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite.withOpacity(0.4))),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted.withOpacity(0.3))),
      enabled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
