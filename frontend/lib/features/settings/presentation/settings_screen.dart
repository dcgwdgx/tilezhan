/// Settings screen providing user-facing configuration, account management,
/// and app information.
///
/// Organized into three sections:
/// - **Learning**: animation speed, daily card goal, and countdown duration.
/// - **Account**: sign-in and purchase restoration (placeholder).
/// - **About**: version number, privacy policy, and terms of service.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A scrollable settings page with sections for Learning, Account, and About.
///
/// Uses [ConsumerWidget] from Riverpod for reactive state access. Each section
/// is rendered as a rounded card with a list of labeled, tappable tiles.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Learning', [
            _tile(Icons.speed, l10n.settingsAnimation, 'Normal'),
            _tile(Icons.flag, 'Daily Goal', '10 cards'),
            _tile(Icons.timer, 'Countdown', '8 seconds'),
          ]),
          const SizedBox(height: 24),
          _section('Account', [
            _tile(Icons.person_outline, 'Sign In', 'Coming soon'),
            _tile(Icons.restore, l10n.premiumRestore, 'Coming soon'),
          ]),
          const SizedBox(height: 24),
          _section('Language', [
            _languageTile(context, ref),
          ]),
          const SizedBox(height: 24),
          _section(l10n.settingsAbout, [
            _tile(Icons.info_outline, 'Version', '1.0.0+1'),
            _linkTile(Icons.shield_outlined, 'Privacy Policy', 'https://tz.slxing.com/privacy.html'),
            _linkTile(Icons.description_outlined, 'Terms of Service', 'https://tz.slxing.com/terms.html'),
          ]),
        ],
      ),
    );
  }

  Widget _languageTile(BuildContext context, WidgetRef ref) {
    final currentName = supportedLanguages
        .firstWhere((l) => l.$1 == localeModel.locale.languageCode,
            orElse: () => const ('en', 'English'))
        .$2;
    return ListTile(
      leading: const Icon(Icons.language, color: AppColors.neonGold),
      title: const Text('App Language', style: TextStyle(color: AppColors.jadeWhite)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(currentName, style: const TextStyle(color: AppColors.neonGold, fontSize: 13)),
        const Icon(Icons.chevron_right, color: AppColors.jadeWhiteMuted),
      ]),
      onTap: () => _showLanguagePicker(context),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.jadeCard,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ...supportedLanguages.map((lang) => ListTile(
          leading: Radio<String>(
            value: lang.$1,
            groupValue: localeModel.locale.languageCode,
            activeColor: AppColors.neonGold,
            onChanged: (v) {
              if (v != null) localeModel.switchTo(v);
              Navigator.pop(context);
            },
          ),
          title: Text(lang.$2, style: const TextStyle(color: AppColors.jadeWhite)),
        )),
      ]),
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

  /// Tappable tile that opens [url] in an external browser.
  Widget _linkTile(IconData icon, String title, String url) => ListTile(
    leading: Icon(icon, color: AppColors.neonGold, size: 22),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite)),
    trailing: const Icon(Icons.open_in_new, color: AppColors.jadeWhiteMuted, size: 16),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
  );
}
