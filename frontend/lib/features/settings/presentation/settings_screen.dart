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
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/locale_provider.dart';

/// A scrollable settings page with sections for Learning, Account, and About.
///
/// Uses [ConsumerWidget] from Riverpod for reactive state access. Each section
/// is rendered as a rounded card with a list of labeled, tappable tiles.
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
          _section('Language', [
            _languageTile(context, ref),
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
}
