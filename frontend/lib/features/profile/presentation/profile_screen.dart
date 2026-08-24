import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/commerce/commerce_availability.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/storage/storage_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../training_plan/data/training_plan_store.dart';

/// Honest, local-first learning profile. Every displayed value has a real
/// writer: ELO, the unified daily-plan streak, or the current SRS due queue.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final storage = ref.watch(storageServiceProvider).valueOrNull;
    final elo = storage?.getIntOrNull(StorageService.kElo) ?? 800;
    final plan = ref.watch(dailyTrainingPlanProvider);
    final dueCount = ref.watch(dueItemsProvider).length;
    final availability = ref.watch(commerceAvailabilityProvider);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
        ),
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.demonPurple, Color(0xFF6C3483)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.demonPurple.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🀄', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profileLocalProgress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.jadeWhiteDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(
                icon: Icons.bolt_rounded,
                value: '$elo',
                label: l10n.profileElo,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.local_fire_department_rounded,
                value: '${plan?.currentStreak ?? 0}',
                label: l10n.profileLearningStreak,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.emoji_events_outlined,
                value: '${plan?.bestStreak ?? 0}',
                label: l10n.profileBestStreak,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n.profileLearningSection,
            children: [
              _ActionTile(
                icon: Icons.today_outlined,
                title: l10n.profileTodayPlan,
                subtitle: plan == null
                    ? l10n.trainingLoading
                    : l10n.profileTodayProgress(
                        plan.completedAttempts,
                        plan.targetAttempts,
                      ),
                onTap: () => context.go('/'),
              ),
              _ActionTile(
                icon: Icons.replay_rounded,
                title: l10n.profileReviewQueue,
                subtitle: l10n.profileReviewDue(dueCount),
                onTap: () => context.push('/graveyard'),
              ),
            ],
          ),
          if (availability.restoreEnabled) ...[
            const SizedBox(height: 24),
            _Section(
              title: l10n.profileAccountSection,
              children: [
                _ActionTile(
                  icon: Icons.restore_rounded,
                  title: l10n.premiumRestore,
                  subtitle: l10n.premiumRestoreHint,
                  onTap: () => context.push('/premium'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _Section(
            title: l10n.profilePreferencesSection,
            children: [
              _ActionTile(
                icon: Icons.settings_outlined,
                title: l10n.profileSettings,
                subtitle: l10n.profileSettingsDesc,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.jadeCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.jadeHover),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.neonGold, size: 23),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.jadeWhite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                height: 1.2,
                color: AppColors.jadeWhiteMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: AppColors.jadeWhiteMuted,
            ),
          ),
        ),
        Material(
          color: AppColors.jadeCard,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.jadeHover),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.neonGold, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.jadeWhite,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.jadeWhiteMuted,
          fontSize: 11,
          height: 1.3,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.jadeWhiteMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}
