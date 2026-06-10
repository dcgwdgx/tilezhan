import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/storage/storage_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider).valueOrNull;
    final elo = storage?.getInt(StorageService.kElo) ?? 1000;
    final streak = storage?.getInt(StorageService.kStreak) ?? 0;
    final level = _levelFromElo(elo);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + level
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.demonPurple, Color(0xFF6C3483)]),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: AppColors.demonPurple.withOpacity(0.3), blurRadius: 16)],
                  ),
                  child: const Center(child: Text('🀄', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 12),
                Text(level.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.neonGold)),
                const SizedBox(height: 4),
                Text('Lv. $level', style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats grid
          Row(
            children: [
              _StatCard(emoji: '⚡', value: '$elo', label: 'ELO'),
              const SizedBox(width: 10),
              _StatCard(emoji: '🔥', value: '$streak', label: 'Streak'),
              const SizedBox(width: 10),
              _StatCard(emoji: '🏆', value: '$level', label: 'Level'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection('Account', [
            _ListTile(icon: Icons.person_outline, title: 'Sign In', subtitle: 'Coming soon — Firebase'),
            _ListTile(icon: Icons.restore, title: 'Restore Purchases', subtitle: 'Coming soon'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Preferences', [
            _ListTile(icon: Icons.speed, title: 'Animation Speed', subtitle: 'Normal', trailing: true),
            _ListTile(icon: Icons.flag, title: 'Daily Goal', subtitle: '10 cards', trailing: true),
          ]),
          const SizedBox(height: 40),
          const Center(child: Text('TileSlash v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.jadeWhiteMuted)),
      ),
      Container(
        decoration: BoxDecoration(color: AppColors.jadeCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.jadeHover)),
        child: Column(children: items),
      ),
    ],
  );

  (String, int) _levelFromElo(int elo) {
    if (elo < 900) return ('Beginner', 1);
    if (elo < 1100) return ('Learner', 2);
    if (elo < 1300) return ('Adept', 3);
    if (elo < 1500) return ('Expert', 4);
    return ('Master', 5);
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  const _StatCard({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.jadeCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.jadeHover)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.jadeWhite)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.jadeWhiteMuted)),
      ]),
    ),
  );
}

class _ListTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final bool trailing;
  const _ListTile({required this.icon, required this.title, required this.subtitle, this.trailing = false});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: trailing ? AppColors.neonGold : AppColors.jadeWhiteMuted.withOpacity(0.4), size: 22),
    title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: trailing ? AppColors.jadeWhite : AppColors.jadeWhite.withOpacity(0.4))),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted.withOpacity(0.5))),
    enabled: trailing,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
