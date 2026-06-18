import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TileSlash'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Master Mahjong, One Tile at a Time'**
  String get appTagline;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Master Tile\nRecognition'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Desc.
  ///
  /// In en, this message translates to:
  /// **'4-choice flashcard quiz for all 34 tiles.\nCorrect = use a heart.\nWrong = review free forever.'**
  String get onboarding1Desc;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Train Tile\nEfficiency'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Desc.
  ///
  /// In en, this message translates to:
  /// **'Draw a tile, then choose the\noptimal discard from your hand.\nPerfect answers get visual rewards.'**
  String get onboarding2Desc;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Start Free'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'No sign-up required.\n10 free puzzles every day.\nUnlock unlimited with Pro.'**
  String get onboarding3Desc;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStart;

  /// No description provided for @homeDailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'DAILY CHALLENGE'**
  String get homeDailyChallenge;

  /// No description provided for @homeDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'3 puzzles. No stamina cost. Claim your daily reward.'**
  String get homeDailyDesc;

  /// No description provided for @homeStartChallenge.
  ///
  /// In en, this message translates to:
  /// **'⚡ START CHALLENGE'**
  String get homeStartChallenge;

  /// No description provided for @homeQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACCESS'**
  String get homeQuickAccess;

  /// No description provided for @homeFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get homeFlashcards;

  /// No description provided for @homeNanikiru.
  ///
  /// In en, this message translates to:
  /// **'Nani-Kiru'**
  String get homeNanikiru;

  /// No description provided for @homeScanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get homeScanner;

  /// No description provided for @homeCollection.
  ///
  /// In en, this message translates to:
  /// **'Yaku Guide'**
  String get homeCollection;

  /// No description provided for @homeGraveyard.
  ///
  /// In en, this message translates to:
  /// **'Graveyard'**
  String get homeGraveyard;

  /// No description provided for @homeTileBrowser.
  ///
  /// In en, this message translates to:
  /// **'Tile Browser'**
  String get homeTileBrowser;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfile;

  /// No description provided for @homePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get homePremium;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get homeRank;

  /// No description provided for @homeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE'**
  String get homeUpgrade;

  /// No description provided for @homePro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get homePro;

  /// No description provided for @homeFreeCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 free'**
  String homeFreeCount(int count);

  /// No description provided for @battleTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Battle Report'**
  String get battleTitle;

  /// No description provided for @battleTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get battleTotal;

  /// No description provided for @battleAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get battleAccuracy;

  /// No description provided for @battleMaxCombo.
  ///
  /// In en, this message translates to:
  /// **'Max Combo'**
  String get battleMaxCombo;

  /// No description provided for @battleMistakeHint.
  ///
  /// In en, this message translates to:
  /// **'Review mistakes anytime — free, no limits'**
  String get battleMistakeHint;

  /// No description provided for @battlePremiumCTA.
  ///
  /// In en, this message translates to:
  /// **'\$4.99/mo  —  Unlimited Play'**
  String get battlePremiumCTA;

  /// No description provided for @battleMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review Past Mistakes'**
  String get battleMistakes;

  /// No description provided for @battleShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get battleShare;

  /// No description provided for @battleInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get battleInvite;

  /// No description provided for @battleMistakesBtn.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get battleMistakesBtn;

  /// No description provided for @battleComboBanner.
  ///
  /// In en, this message translates to:
  /// **'COMBO ×10!'**
  String get battleComboBanner;

  /// No description provided for @battleComboSub.
  ///
  /// In en, this message translates to:
  /// **'Annual 20% OFF — \$23.99/yr'**
  String get battleComboSub;

  /// No description provided for @battleComboUnlock.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK'**
  String get battleComboUnlock;

  /// No description provided for @battleDomain.
  ///
  /// In en, this message translates to:
  /// **'tilezhan.app'**
  String get battleDomain;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get premiumTitle;

  /// No description provided for @premiumConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to App Store...'**
  String get premiumConnecting;

  /// No description provided for @premiumContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get premiumContinue;

  /// No description provided for @premiumSelectPlan.
  ///
  /// In en, this message translates to:
  /// **'SELECT A PLAN'**
  String get premiumSelectPlan;

  /// No description provided for @premiumPurchasing.
  ///
  /// In en, this message translates to:
  /// **'PURCHASING...'**
  String get premiumPurchasing;

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get premiumRestore;

  /// No description provided for @premiumAllPlansHeader.
  ///
  /// In en, this message translates to:
  /// **'All paid plans include:'**
  String get premiumAllPlansHeader;

  /// No description provided for @premiumAllPlansFooter.
  ///
  /// In en, this message translates to:
  /// **'✅ Unlimited puzzle replay   ✅ Ghost Mode (mistake review)   ✅ Cancel anytime'**
  String get premiumAllPlansFooter;

  /// No description provided for @premiumFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get premiumFree;

  /// No description provided for @premiumMonthly.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY'**
  String get premiumMonthly;

  /// No description provided for @premiumAnnual.
  ///
  /// In en, this message translates to:
  /// **'ANNUAL'**
  String get premiumAnnual;

  /// No description provided for @premiumLifetime.
  ///
  /// In en, this message translates to:
  /// **'LIFETIME'**
  String get premiumLifetime;

  /// No description provided for @premiumPopular.
  ///
  /// In en, this message translates to:
  /// **'★ POPULAR'**
  String get premiumPopular;

  /// No description provided for @premiumBestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE — Save 50%'**
  String get premiumBestValue;

  /// No description provided for @premiumPayOnce.
  ///
  /// In en, this message translates to:
  /// **'PAY ONCE'**
  String get premiumPayOnce;

  /// No description provided for @premiumLaunchBanner.
  ///
  /// In en, this message translates to:
  /// **'Launch Special: Lifetime 20% OFF — Limited Time'**
  String get premiumLaunchBanner;

  /// No description provided for @shareStats.
  ///
  /// In en, this message translates to:
  /// **'🎯 {total} puzzles today · {accuracy}% accuracy · {combo}× max combo on TileZhan! tilezhan.app'**
  String shareStats(Object total, Object accuracy, Object combo);

  /// No description provided for @inviteText.
  ///
  /// In en, this message translates to:
  /// **'🀄 Join me on TileZhan — master Mahjong tile recognition! Free daily puzzles. Get it at tilezhan.app'**
  String get inviteText;

  /// No description provided for @comboTitle.
  ///
  /// In en, this message translates to:
  /// **'COMBO ×10!'**
  String get comboTitle;

  /// No description provided for @comboSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on fire! Unlock unlimited play\nand keep your streak alive.'**
  String get comboSubtitle;

  /// No description provided for @comboOffer.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL OFFER'**
  String get comboOffer;

  /// No description provided for @comboDiscount.
  ///
  /// In en, this message translates to:
  /// **'20% OFF'**
  String get comboDiscount;

  /// No description provided for @comboUnlock.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK NOW — \$23.99'**
  String get comboUnlock;

  /// No description provided for @comboMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get comboMaybe;

  /// No description provided for @nanikiruDraw.
  ///
  /// In en, this message translates to:
  /// **'You just drew:'**
  String get nanikiruDraw;

  /// No description provided for @nanikiruCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct discard: {discard}'**
  String nanikiruCorrect(Object discard);

  /// No description provided for @nanikiruYourDiscard.
  ///
  /// In en, this message translates to:
  /// **'Your discard: {discard}'**
  String nanikiruYourDiscard(Object discard);

  /// No description provided for @nanikiruBestDiscard.
  ///
  /// In en, this message translates to:
  /// **'Best discard: {discard}  →  {count} tile types, {types} acceptance tiles'**
  String nanikiruBestDiscard(Object discard, Object count, Object types);

  /// No description provided for @nanikiruPerfectExplain.
  ///
  /// In en, this message translates to:
  /// **'Maximizing tile acceptance — this discard gives you the most ways to complete your hand.'**
  String get nanikiruPerfectExplain;

  /// No description provided for @nanikiruHint.
  ///
  /// In en, this message translates to:
  /// **'Look for sequences and triplets.\nDiscard isolated tiles that don\'t form any meld.\nThe correct answer maximizes tile acceptance (ukeire).'**
  String get nanikiruHint;

  /// No description provided for @nanikiruSkip.
  ///
  /// In en, this message translates to:
  /// **'🏳️ Skip'**
  String get nanikiruSkip;

  /// No description provided for @nanikiruConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get nanikiruConfirm;

  /// No description provided for @nanikiruTapToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to continue'**
  String get nanikiruTapToContinue;

  /// No description provided for @nanikiruPerfect.
  ///
  /// In en, this message translates to:
  /// **'🎯 PERFECT!'**
  String get nanikiruPerfect;

  /// No description provided for @nanikiruBlunder.
  ///
  /// In en, this message translates to:
  /// **'💥 BLUNDER!'**
  String get nanikiruBlunder;

  /// No description provided for @nanikiruAcceptanceTiles.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Tiles'**
  String get nanikiruAcceptanceTiles;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Yaku Scanner'**
  String get scannerTitle;

  /// No description provided for @scannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Full hand scanning coming in V2.\nBrowse all 10 basic yaku below.'**
  String get scannerDesc;

  /// No description provided for @scannerBasicYaku.
  ///
  /// In en, this message translates to:
  /// **'BASIC YAKU'**
  String get scannerBasicYaku;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Be the first to rank!'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Complete puzzles to earn your spot.'**
  String get leaderboardEmptySub;

  /// No description provided for @leaderboardRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get leaderboardRetry;

  /// No description provided for @flashcardTimer.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get flashcardTimer;

  /// No description provided for @flashcardPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get flashcardPerfect;

  /// No description provided for @flashcardCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get flashcardCorrect;

  /// No description provided for @flashcardIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get flashcardIncorrect;

  /// No description provided for @flashcardTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get flashcardTimeout;

  /// No description provided for @flashcardPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'🔄 Play Again'**
  String get flashcardPlayAgain;

  /// No description provided for @flashcardGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it ✓'**
  String get flashcardGotIt;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// No description provided for @settingsAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation Speed'**
  String get settingsAnimation;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsVersion;

  /// No description provided for @rankNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get rankNovice;

  /// No description provided for @rankApprentice.
  ///
  /// In en, this message translates to:
  /// **'Apprentice'**
  String get rankApprentice;

  /// No description provided for @rankAdept.
  ///
  /// In en, this message translates to:
  /// **'Adept'**
  String get rankAdept;

  /// No description provided for @rankExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get rankExpert;

  /// No description provided for @rankMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get rankMaster;

  /// No description provided for @rankReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String rankReviews(Object count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTiles.
  ///
  /// In en, this message translates to:
  /// **'Tiles'**
  String get navTiles;

  /// No description provided for @navYaku.
  ///
  /// In en, this message translates to:
  /// **'Yaku'**
  String get navYaku;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
