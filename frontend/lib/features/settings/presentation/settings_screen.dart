import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/commerce/commerce_availability.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Settings exposes only working controls. Placeholder toggles and fake
/// account actions are deliberately omitted from a commercial build.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _privacyUrl = 'https://tz.slxing.com/privacy.html';
  static const _termsUrl = 'https://tz.slxing.com/terms.html';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
          l10n.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: l10n.settingsLanguageSection,
            children: [_languageTile(context, ref, l10n)],
          ),
          if (availability.restoreEnabled) ...[
            const SizedBox(height: 24),
            _Section(
              title: l10n.settingsAccount,
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
            title: l10n.settingsAbout,
            children: [
              _InfoTile(
                icon: Icons.info_outline_rounded,
                title: l10n.settingsVersionLabel,
                value: '1.0.1+4',
              ),
              _ActionTile(
                icon: Icons.shield_outlined,
                title: l10n.premiumPrivacy,
                onTap: () => _open(_privacyUrl),
              ),
              _ActionTile(
                icon: Icons.description_outlined,
                title: l10n.premiumTerms,
                onTap: () => _open(_termsUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _languageTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final currentName = supportedLanguages
        .firstWhere(
          (language) => language.$1 == localeModel.locale.languageCode,
          orElse: () => const ('en', 'English'),
        )
        .$2;
    return _ActionTile(
      icon: Icons.language_rounded,
      title: l10n.settingsAppLanguage,
      value: currentName,
      onTap: () => _showLanguagePicker(context),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.jadeCard,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final language in supportedLanguages)
              RadioListTile<String>(
                value: language.$1,
                groupValue: localeModel.locale.languageCode,
                activeColor: AppColors.neonGold,
                title: Text(
                  language.$2,
                  style: const TextStyle(color: AppColors.jadeWhite),
                ),
                onChanged: (value) {
                  if (value != null) localeModel.switchTo(value);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
              letterSpacing: 1.5,
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
    required this.onTap,
    this.subtitle,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
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
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.jadeWhiteMuted,
                fontSize: 11,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                color: AppColors.neonGold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.jadeWhiteMuted,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.jadeWhiteMuted, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.jadeWhite,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          color: AppColors.jadeWhiteMuted,
          fontSize: 12,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
