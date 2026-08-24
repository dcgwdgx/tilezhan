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
  /// **'4-choice flashcard quiz for all 34 tiles.\nCorrect answers are always free.\nMistakes enter your review queue.'**
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
  /// **'Build a Daily\nLearning Habit'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'Follow a short plan tailored to your reviews and recent practice.\nNo sign-up required. All training is free in this version.'**
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
  /// **'Start First Lesson'**
  String get onboardingStart;

  /// No description provided for @homeDailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'DAILY CHALLENGE'**
  String get homeDailyChallenge;

  /// No description provided for @homeDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 tile-efficiency puzzles with no stamina cost and build your daily streak.'**
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

  /// No description provided for @homeDefenseTraining.
  ///
  /// In en, this message translates to:
  /// **'Defense Trainer'**
  String get homeDefenseTraining;

  /// No description provided for @homeScanner.
  ///
  /// In en, this message translates to:
  /// **'Yaku Reference'**
  String get homeScanner;

  /// No description provided for @homeHandAnalyzer.
  ///
  /// In en, this message translates to:
  /// **'Hand Analyzer'**
  String get homeHandAnalyzer;

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

  /// No description provided for @homeHeartsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} hearts remaining'**
  String homeHeartsRemaining(int count);

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'🔥 {count}-day streak'**
  String dailyStreak(int count);

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String dailyProgress(int current, int total);

  /// No description provided for @dailyViewResult.
  ///
  /// In en, this message translates to:
  /// **'VIEW TODAY\'S RESULT'**
  String get dailyViewResult;

  /// No description provided for @dailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge Complete'**
  String get dailySummaryTitle;

  /// No description provided for @dailySummaryBody.
  ///
  /// In en, this message translates to:
  /// **'You solved {correct}/{total} puzzles correctly.\nAccuracy: {accuracy}%\nLearning streak: {streak} days'**
  String dailySummaryBody(int correct, int total, int accuracy, int streak);

  /// No description provided for @trainingLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing today\'s plan...'**
  String get trainingLoading;

  /// No description provided for @trainingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan could not be loaded. You can retry without losing saved progress.'**
  String get trainingLoadError;

  /// No description provided for @trainingRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY PLAN'**
  String get trainingRetry;

  /// No description provided for @trainingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Your progress could not be saved. Check device storage, then try again.'**
  String get trainingSaveError;

  /// No description provided for @trainingSaveRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY SAVE'**
  String get trainingSaveRetry;

  /// No description provided for @trainingTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s 5-minute plan'**
  String get trainingTodayTitle;

  /// No description provided for @trainingTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A focused path based on your reviews and recent practice.'**
  String get trainingTodaySubtitle;

  /// No description provided for @trainingPlanProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} completed'**
  String trainingPlanProgress(int current, int total);

  /// No description provided for @trainingStreakStart.
  ///
  /// In en, this message translates to:
  /// **'Start your learning streak'**
  String get trainingStreakStart;

  /// No description provided for @trainingLearningStreak.
  ///
  /// In en, this message translates to:
  /// **'🔥 {count}-day learning streak'**
  String trainingLearningStreak(int count);

  /// No description provided for @trainingPlanComplete.
  ///
  /// In en, this message translates to:
  /// **'PLAN COMPLETE'**
  String get trainingPlanComplete;

  /// No description provided for @trainingStartPlan.
  ///
  /// In en, this message translates to:
  /// **'START TODAY\'S PLAN'**
  String get trainingStartPlan;

  /// No description provided for @trainingContinuePlan.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE PLAN'**
  String get trainingContinuePlan;

  /// No description provided for @trainingTaskStarterTiles.
  ///
  /// In en, this message translates to:
  /// **'Learn the core tiles'**
  String get trainingTaskStarterTiles;

  /// No description provided for @trainingTaskDueReview.
  ///
  /// In en, this message translates to:
  /// **'Clear today\'s reviews'**
  String get trainingTaskDueReview;

  /// No description provided for @trainingTaskWeakSkill.
  ///
  /// In en, this message translates to:
  /// **'Strengthen {skill}'**
  String trainingTaskWeakSkill(String skill);

  /// No description provided for @trainingTaskDailyEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Daily efficiency challenge'**
  String get trainingTaskDailyEfficiency;

  /// No description provided for @trainingTaskExploreDefense.
  ///
  /// In en, this message translates to:
  /// **'Explore defensive reading'**
  String get trainingTaskExploreDefense;

  /// No description provided for @trainingTaskExploreYaku.
  ///
  /// In en, this message translates to:
  /// **'Explore yaku knowledge'**
  String get trainingTaskExploreYaku;

  /// No description provided for @trainingTaskStarterDesc.
  ///
  /// In en, this message translates to:
  /// **'Build instant recognition with three quick flashcards.'**
  String get trainingTaskStarterDesc;

  /// No description provided for @trainingTaskDueDesc.
  ///
  /// In en, this message translates to:
  /// **'Review {count} item(s) scheduled for today.'**
  String trainingTaskDueDesc(int count);

  /// No description provided for @trainingTaskDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Make three discard decisions and compare tile efficiency.'**
  String get trainingTaskDailyDesc;

  /// No description provided for @trainingTaskExploreDefenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn to rank safe discards from visible evidence.'**
  String get trainingTaskExploreDefenseDesc;

  /// No description provided for @trainingTaskExploreYakuDesc.
  ///
  /// In en, this message translates to:
  /// **'Check the definitions and rules that make a winning hand valid.'**
  String get trainingTaskExploreYakuDesc;

  /// No description provided for @trainingTaskWeakDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice focused questions selected from this weak area.'**
  String get trainingTaskWeakDesc;

  /// No description provided for @trainingTaskWeakEvidence.
  ///
  /// In en, this message translates to:
  /// **'Recent evidence: {correct}/{attempts} correct'**
  String trainingTaskWeakEvidence(int correct, int attempts);

  /// No description provided for @trainingSkillIsolatedTiles.
  ///
  /// In en, this message translates to:
  /// **'isolated-tile choices'**
  String get trainingSkillIsolatedTiles;

  /// No description provided for @trainingSkillTaatsuOverload.
  ///
  /// In en, this message translates to:
  /// **'overloaded shapes'**
  String get trainingSkillTaatsuOverload;

  /// No description provided for @trainingSkillPairProtection.
  ///
  /// In en, this message translates to:
  /// **'pair protection'**
  String get trainingSkillPairProtection;

  /// No description provided for @trainingSkillChiitoitsuChoice.
  ///
  /// In en, this message translates to:
  /// **'seven-pairs decisions'**
  String get trainingSkillChiitoitsuChoice;

  /// No description provided for @trainingSkillKokushiShape.
  ///
  /// In en, this message translates to:
  /// **'thirteen-orphans shapes'**
  String get trainingSkillKokushiShape;

  /// No description provided for @trainingSkillTileEfficiency.
  ///
  /// In en, this message translates to:
  /// **'tile efficiency'**
  String get trainingSkillTileEfficiency;

  /// No description provided for @trainingSkillGeneral.
  ///
  /// In en, this message translates to:
  /// **'recent weak areas'**
  String get trainingSkillGeneral;

  /// No description provided for @dailySummaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dailySummaryDone;

  /// No description provided for @reviewFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish Review'**
  String get reviewFinish;

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
  /// **'View Premium Options'**
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
  /// **'See the plans currently available in the store'**
  String get battleComboSub;

  /// No description provided for @battleComboUnlock.
  ///
  /// In en, this message translates to:
  /// **'VIEW OPTIONS'**
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
  /// **'Connecting to the store...'**
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

  /// No description provided for @premiumFreeReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'All training is free in this version'**
  String get premiumFreeReleaseTitle;

  /// No description provided for @premiumFreeReleaseBody.
  ///
  /// In en, this message translates to:
  /// **'Practice without stamina or difficulty limits. Your results and mistake reviews remain available.'**
  String get premiumFreeReleaseBody;

  /// No description provided for @premiumRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Already purchased in an earlier version? Restore your purchase history here.'**
  String get premiumRestoreHint;

  /// No description provided for @premiumRestoring.
  ///
  /// In en, this message translates to:
  /// **'RESTORING...'**
  String get premiumRestoring;

  /// No description provided for @premiumRestoreRequested.
  ///
  /// In en, this message translates to:
  /// **'Restore request sent. Your access will update after the store confirms it.'**
  String get premiumRestoreRequested;

  /// No description provided for @premiumRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchases could not be restored. Please try again.'**
  String get premiumRestoreFailed;

  /// No description provided for @premiumNoProducts.
  ///
  /// In en, this message translates to:
  /// **'Purchases are temporarily unavailable. No store products are currently offered.'**
  String get premiumNoProducts;

  /// No description provided for @premiumUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is temporarily unavailable. Please try again later.'**
  String get premiumUnavailable;

  /// No description provided for @premiumRetry.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get premiumRetry;

  /// No description provided for @premiumPurchaseStarted.
  ///
  /// In en, this message translates to:
  /// **'Purchase request sent. Follow the store prompts to finish.'**
  String get premiumPurchaseStarted;

  /// No description provided for @premiumPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be started. Please try again.'**
  String get premiumPurchaseFailed;

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

  /// No description provided for @premiumPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get premiumPrivacy;

  /// No description provided for @premiumTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get premiumTerms;

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
  /// **'Best discard: {discard}  →  {types} types, {count} acceptance tiles'**
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

  /// No description provided for @nanikiruNextPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Next Puzzle'**
  String get nanikiruNextPuzzle;

  /// No description provided for @nanikiruReviewAgain.
  ///
  /// In en, this message translates to:
  /// **'Review Again'**
  String get nanikiruReviewAgain;

  /// No description provided for @nanikiruAcceptanceComparison.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Comparison'**
  String get nanikiruAcceptanceComparison;

  /// No description provided for @nanikiruYourDiscardLabel.
  ///
  /// In en, this message translates to:
  /// **'Your discard'**
  String get nanikiruYourDiscardLabel;

  /// No description provided for @nanikiruBestDiscardLabel.
  ///
  /// In en, this message translates to:
  /// **'Best discard'**
  String get nanikiruBestDiscardLabel;

  /// No description provided for @nanikiruSkippedTitle.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED'**
  String get nanikiruSkippedTitle;

  /// No description provided for @nanikiruTimedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'TIME\'S UP!'**
  String get nanikiruTimedOutTitle;

  /// No description provided for @nanikiruTopCandidatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Top discard candidates'**
  String get nanikiruTopCandidatesTitle;

  /// No description provided for @nanikiruBestBadge.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get nanikiruBestBadge;

  /// No description provided for @nanikiruSelectedBadge.
  ///
  /// In en, this message translates to:
  /// **'YOUR CHOICE'**
  String get nanikiruSelectedBadge;

  /// No description provided for @nanikiruTenpai.
  ///
  /// In en, this message translates to:
  /// **'Tenpai'**
  String get nanikiruTenpai;

  /// No description provided for @nanikiruShantenValue.
  ///
  /// In en, this message translates to:
  /// **'{shanten}-shanten'**
  String nanikiruShantenValue(int shanten);

  /// No description provided for @nanikiruAcceptanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Types: {types} · Tiles: {count}'**
  String nanikiruAcceptanceSummary(int types, int count);

  /// No description provided for @nanikiruUkeireLoss.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 fewer acceptance tile than the best discard} other{{count} fewer acceptance tiles than the best discard}}'**
  String nanikiruUkeireLoss(int count);

  /// No description provided for @nanikiruShantenLoss.
  ///
  /// In en, this message translates to:
  /// **'Falls back by {shanten} shanten'**
  String nanikiruShantenLoss(int shanten);

  /// No description provided for @nanikiruNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No tile selected'**
  String get nanikiruNoSelection;

  /// No description provided for @nanikiruTimeoutChoice.
  ///
  /// In en, this message translates to:
  /// **'Choice when time expired: {discard}'**
  String nanikiruTimeoutChoice(String discard);

  /// No description provided for @nanikiruSkillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills trained'**
  String get nanikiruSkillsTitle;

  /// No description provided for @nanikiruTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get nanikiruTypesLabel;

  /// No description provided for @nanikiruSkillIsolatedTile.
  ///
  /// In en, this message translates to:
  /// **'Isolated tile handling'**
  String get nanikiruSkillIsolatedTile;

  /// No description provided for @nanikiruSkillTaatsuOverload.
  ///
  /// In en, this message translates to:
  /// **'Taatsu selection'**
  String get nanikiruSkillTaatsuOverload;

  /// No description provided for @nanikiruSkillPairProtection.
  ///
  /// In en, this message translates to:
  /// **'Pair preservation'**
  String get nanikiruSkillPairProtection;

  /// No description provided for @nanikiruSkillChiitoitsu.
  ///
  /// In en, this message translates to:
  /// **'Seven Pairs path'**
  String get nanikiruSkillChiitoitsu;

  /// No description provided for @nanikiruSkillKokushi.
  ///
  /// In en, this message translates to:
  /// **'Thirteen Orphans path'**
  String get nanikiruSkillKokushi;

  /// No description provided for @nanikiruSkillGeneralEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Tile efficiency'**
  String get nanikiruSkillGeneralEfficiency;

  /// No description provided for @nanikiruNotOptimalTitle.
  ///
  /// In en, this message translates to:
  /// **'NOT OPTIMAL'**
  String get nanikiruNotOptimalTitle;

  /// No description provided for @nanikiruDecisionLossTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision impact'**
  String get nanikiruDecisionLossTitle;

  /// No description provided for @nanikiruNoDecisionLoss.
  ///
  /// In en, this message translates to:
  /// **'Best choice — no efficiency loss'**
  String get nanikiruNoDecisionLoss;

  /// No description provided for @nanikiruRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank #{rank}'**
  String nanikiruRankLabel(int rank);

  /// No description provided for @nanikiruDiscardLabel.
  ///
  /// In en, this message translates to:
  /// **'Discard: {tile}'**
  String nanikiruDiscardLabel(String tile);

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Yaku Reference'**
  String get scannerTitle;

  /// No description provided for @scannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse the yaku reference below or open the Yaku Dojo to test your knowledge.'**
  String get scannerDesc;

  /// No description provided for @scannerBasicYaku.
  ///
  /// In en, this message translates to:
  /// **'BASIC YAKU'**
  String get scannerBasicYaku;

  /// No description provided for @scannerFavorites.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get scannerFavorites;

  /// No description provided for @scannerBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get scannerBeginner;

  /// No description provided for @scannerIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get scannerIntermediate;

  /// No description provided for @scannerAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get scannerAdvanced;

  /// No description provided for @scannerYakuman.
  ///
  /// In en, this message translates to:
  /// **'Yakuman'**
  String get scannerYakuman;

  /// No description provided for @scannerYakuCount.
  ///
  /// In en, this message translates to:
  /// **'{count} yaku'**
  String scannerYakuCount(int count);

  /// No description provided for @handAnalyzerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand Analyzer'**
  String get handAnalyzerTitle;

  /// No description provided for @handAnalyzerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a closed 13- or 14-tile hand for exact tile-efficiency analysis.'**
  String get handAnalyzerSubtitle;

  /// No description provided for @handAnalyzerScope.
  ///
  /// In en, this message translates to:
  /// **'Pure tile efficiency only. Dora, yaku, points, visible tiles, calls, and defense are not considered.'**
  String get handAnalyzerScope;

  /// No description provided for @handAnalyzerHand.
  ///
  /// In en, this message translates to:
  /// **'YOUR HAND'**
  String get handAnalyzerHand;

  /// No description provided for @handAnalyzerTileCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {target} tiles'**
  String handAnalyzerTileCount(int count, int target);

  /// No description provided for @handAnalyzerNeedTileCount.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 13 or 14 tiles to analyze.'**
  String get handAnalyzerNeedTileCount;

  /// No description provided for @handAnalyzerFourCopyLimit.
  ///
  /// In en, this message translates to:
  /// **'A tile can appear at most four times.'**
  String get handAnalyzerFourCopyLimit;

  /// No description provided for @handAnalyzerRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a tile in your hand to remove it.'**
  String get handAnalyzerRemoveHint;

  /// No description provided for @handAnalyzerPicker.
  ///
  /// In en, this message translates to:
  /// **'ADD TILES'**
  String get handAnalyzerPicker;

  /// No description provided for @handAnalyzerMan.
  ///
  /// In en, this message translates to:
  /// **'Manzu'**
  String get handAnalyzerMan;

  /// No description provided for @handAnalyzerPin.
  ///
  /// In en, this message translates to:
  /// **'Pinzu'**
  String get handAnalyzerPin;

  /// No description provided for @handAnalyzerSou.
  ///
  /// In en, this message translates to:
  /// **'Souzu'**
  String get handAnalyzerSou;

  /// No description provided for @handAnalyzerHonors.
  ///
  /// In en, this message translates to:
  /// **'Honors'**
  String get handAnalyzerHonors;

  /// No description provided for @handAnalyzerAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze Hand'**
  String get handAnalyzerAnalyze;

  /// No description provided for @handAnalyzerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get handAnalyzerClear;

  /// No description provided for @handAnalyzerCurrentShanten.
  ///
  /// In en, this message translates to:
  /// **'Current shanten'**
  String get handAnalyzerCurrentShanten;

  /// No description provided for @handAnalyzerComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete hand'**
  String get handAnalyzerComplete;

  /// No description provided for @handAnalyzerTenpai.
  ///
  /// In en, this message translates to:
  /// **'Tenpai'**
  String get handAnalyzerTenpai;

  /// No description provided for @handAnalyzerShantenValue.
  ///
  /// In en, this message translates to:
  /// **'{count}-shanten'**
  String handAnalyzerShantenValue(int count);

  /// No description provided for @handAnalyzerImprovingTiles.
  ///
  /// In en, this message translates to:
  /// **'Improving tiles'**
  String get handAnalyzerImprovingTiles;

  /// No description provided for @handAnalyzerEffectiveSummary.
  ///
  /// In en, this message translates to:
  /// **'{types} types · {count} tiles'**
  String handAnalyzerEffectiveSummary(int types, int count);

  /// No description provided for @handAnalyzerDiscardCandidates.
  ///
  /// In en, this message translates to:
  /// **'Discard candidates'**
  String get handAnalyzerDiscardCandidates;

  /// No description provided for @handAnalyzerCandidateSummary.
  ///
  /// In en, this message translates to:
  /// **'After discard: {shanten} · {types} types · {count} tiles'**
  String handAnalyzerCandidateSummary(String shanten, int types, int count);

  /// No description provided for @handAnalyzerBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get handAnalyzerBest;

  /// No description provided for @handAnalyzerRank.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String handAnalyzerRank(int rank);

  /// No description provided for @handAnalyzerNoImprovingTiles.
  ///
  /// In en, this message translates to:
  /// **'No improving tiles for this state.'**
  String get handAnalyzerNoImprovingTiles;

  /// No description provided for @handAnalyzerSave.
  ///
  /// In en, this message translates to:
  /// **'Save Analysis'**
  String get handAnalyzerSave;

  /// No description provided for @handAnalyzerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to recent analyses.'**
  String get handAnalyzerSaved;

  /// No description provided for @handAnalyzerRecent.
  ///
  /// In en, this message translates to:
  /// **'RECENT ANALYSES'**
  String get handAnalyzerRecent;

  /// No description provided for @handAnalyzerRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Saved hands will appear here.'**
  String get handAnalyzerRecentEmpty;

  /// No description provided for @handAnalyzerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get handAnalyzerOpen;

  /// No description provided for @handAnalyzerDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get handAnalyzerDelete;

  /// No description provided for @handAnalyzerShapeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Shape breakdown'**
  String get handAnalyzerShapeBreakdown;

  /// No description provided for @handAnalyzerStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get handAnalyzerStandard;

  /// No description provided for @handAnalyzerSevenPairs.
  ///
  /// In en, this message translates to:
  /// **'Seven pairs'**
  String get handAnalyzerSevenPairs;

  /// No description provided for @handAnalyzerThirteenOrphans.
  ///
  /// In en, this message translates to:
  /// **'Thirteen orphans'**
  String get handAnalyzerThirteenOrphans;

  /// No description provided for @handAnalyzerError.
  ///
  /// In en, this message translates to:
  /// **'This hand could not be analyzed. Check the tile count and try again.'**
  String get handAnalyzerError;

  /// No description provided for @defenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Defense Trainer'**
  String get defenseTitle;

  /// No description provided for @defenseIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Read the danger before you discard'**
  String get defenseIntroTitle;

  /// No description provided for @defenseIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Practice choosing the lowest-risk tile against one riichi opponent using visible evidence.'**
  String get defenseIntroBody;

  /// No description provided for @defenseScope.
  ///
  /// In en, this message translates to:
  /// **'Genbutsu is safe only against the target player. Suji, kabe, and visible honors can reduce some risks but never guarantee safety.'**
  String get defenseScope;

  /// No description provided for @defenseSessionLength.
  ///
  /// In en, this message translates to:
  /// **'{count}-question session'**
  String defenseSessionLength(int count);

  /// No description provided for @defenseStart.
  ///
  /// In en, this message translates to:
  /// **'Start Training'**
  String get defenseStart;

  /// No description provided for @defenseProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String defenseProgress(int current, int total);

  /// No description provided for @defenseQuestionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Which discard has the lowest risk against the target player in this scenario?'**
  String get defenseQuestionPrompt;

  /// No description provided for @defenseTargetRiver.
  ///
  /// In en, this message translates to:
  /// **'Riichi target river · {seat}'**
  String defenseTargetRiver(String seat);

  /// No description provided for @defenseOtherRiver.
  ///
  /// In en, this message translates to:
  /// **'Other river · {seat}'**
  String defenseOtherRiver(String seat);

  /// No description provided for @defenseAdditionalVisible.
  ///
  /// In en, this message translates to:
  /// **'OTHER VISIBLE TILES'**
  String get defenseAdditionalVisible;

  /// No description provided for @defenseVisibleCopies.
  ///
  /// In en, this message translates to:
  /// **'{count} visible'**
  String defenseVisibleCopies(int count);

  /// No description provided for @defenseVisibleTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'{tile}, {count} visible copies'**
  String defenseVisibleTileSemantics(String tile, int count);

  /// No description provided for @defenseTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tile {tile}'**
  String defenseTileSemantics(String tile);

  /// No description provided for @defenseNumberedTile.
  ///
  /// In en, this message translates to:
  /// **'{number} of {suit}'**
  String defenseNumberedTile(int number, String suit);

  /// No description provided for @defenseTileManSuit.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get defenseTileManSuit;

  /// No description provided for @defenseTilePinSuit.
  ///
  /// In en, this message translates to:
  /// **'circles'**
  String get defenseTilePinSuit;

  /// No description provided for @defenseTileSouSuit.
  ///
  /// In en, this message translates to:
  /// **'bamboo'**
  String get defenseTileSouSuit;

  /// No description provided for @defenseTileEastWind.
  ///
  /// In en, this message translates to:
  /// **'East Wind'**
  String get defenseTileEastWind;

  /// No description provided for @defenseTileSouthWind.
  ///
  /// In en, this message translates to:
  /// **'South Wind'**
  String get defenseTileSouthWind;

  /// No description provided for @defenseTileWestWind.
  ///
  /// In en, this message translates to:
  /// **'West Wind'**
  String get defenseTileWestWind;

  /// No description provided for @defenseTileNorthWind.
  ///
  /// In en, this message translates to:
  /// **'North Wind'**
  String get defenseTileNorthWind;

  /// No description provided for @defenseTileRedDragon.
  ///
  /// In en, this message translates to:
  /// **'Red Dragon'**
  String get defenseTileRedDragon;

  /// No description provided for @defenseTileGreenDragon.
  ///
  /// In en, this message translates to:
  /// **'Green Dragon'**
  String get defenseTileGreenDragon;

  /// No description provided for @defenseTileWhiteDragon.
  ///
  /// In en, this message translates to:
  /// **'White Dragon'**
  String get defenseTileWhiteDragon;

  /// No description provided for @defenseChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A DISCARD'**
  String get defenseChoicesTitle;

  /// No description provided for @defenseChooseTile.
  ///
  /// In en, this message translates to:
  /// **'Choose {tile}'**
  String defenseChooseTile(String tile);

  /// No description provided for @defenseLoadError.
  ///
  /// In en, this message translates to:
  /// **'The defense lesson could not be loaded.'**
  String get defenseLoadError;

  /// No description provided for @defenseRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get defenseRetry;

  /// No description provided for @defenseTopicGenbutsu.
  ///
  /// In en, this message translates to:
  /// **'Genbutsu'**
  String get defenseTopicGenbutsu;

  /// No description provided for @defenseTopicSuji.
  ///
  /// In en, this message translates to:
  /// **'Suji'**
  String get defenseTopicSuji;

  /// No description provided for @defenseTopicKabe.
  ///
  /// In en, this message translates to:
  /// **'Kabe'**
  String get defenseTopicKabe;

  /// No description provided for @defenseTopicHonorVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visible honors'**
  String get defenseTopicHonorVisibility;

  /// No description provided for @defenseTopicCombinedEvidence.
  ///
  /// In en, this message translates to:
  /// **'Combined evidence'**
  String get defenseTopicCombinedEvidence;

  /// No description provided for @defenseSeatEast.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get defenseSeatEast;

  /// No description provided for @defenseSeatSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get defenseSeatSouth;

  /// No description provided for @defenseSeatWest.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get defenseSeatWest;

  /// No description provided for @defenseSeatNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get defenseSeatNorth;

  /// No description provided for @defenseGoodDecision.
  ///
  /// In en, this message translates to:
  /// **'Good decision'**
  String get defenseGoodDecision;

  /// No description provided for @defenseReviewChoice.
  ///
  /// In en, this message translates to:
  /// **'Review this choice'**
  String get defenseReviewChoice;

  /// No description provided for @defenseYourChoice.
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get defenseYourChoice;

  /// No description provided for @defenseRecommendedChoice.
  ///
  /// In en, this message translates to:
  /// **'Recommended choice'**
  String get defenseRecommendedChoice;

  /// No description provided for @defenseSelected.
  ///
  /// In en, this message translates to:
  /// **'SELECTED'**
  String get defenseSelected;

  /// No description provided for @defenseRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get defenseRecommended;

  /// No description provided for @defenseEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Defensive evidence'**
  String get defenseEvidenceTitle;

  /// No description provided for @defenseRiskAbsoluteAgainstTarget.
  ///
  /// In en, this message translates to:
  /// **'Safe against target · genbutsu'**
  String get defenseRiskAbsoluteAgainstTarget;

  /// No description provided for @defenseRiskStronglyReducedNotAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Strongly reduced risk · not guaranteed safe'**
  String get defenseRiskStronglyReducedNotAbsolute;

  /// No description provided for @defenseRiskRelativelyReducedNotAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Lower-risk clue · not guaranteed safe'**
  String get defenseRiskRelativelyReducedNotAbsolute;

  /// No description provided for @defenseRiskNoEstablishedReduction.
  ///
  /// In en, this message translates to:
  /// **'No established risk reduction'**
  String get defenseRiskNoEstablishedReduction;

  /// No description provided for @defenseExplainTargetOwnDiscardIsGenbutsu.
  ///
  /// In en, this message translates to:
  /// **'This tile appears in the target player\'s own river. Furiten prevents that player from winning by ron on the same tile; it says nothing about the other players.'**
  String get defenseExplainTargetOwnDiscardIsGenbutsu;

  /// No description provided for @defenseExplainOtherOpponentDiscardIsNotTargetGenbutsu.
  ///
  /// In en, this message translates to:
  /// **'This tile appears only in another player\'s river, so it is not genbutsu against the target.'**
  String get defenseExplainOtherOpponentDiscardIsNotTargetGenbutsu;

  /// No description provided for @defenseExplainSujiCoversOnlyRyanmen.
  ///
  /// In en, this message translates to:
  /// **'The target\'s river provides a suji clue that removes some two-sided sequence waits. Tanki, shanpon, edge, closed, and special-hand waits can remain.'**
  String get defenseExplainSujiCoversOnlyRyanmen;

  /// No description provided for @defenseExplainCompleteKabeStillNotAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Four visible copies form a complete kabe and remove the relevant sequence route. Pair and special-hand waits can still remain.'**
  String get defenseExplainCompleteKabeStillNotAbsolute;

  /// No description provided for @defenseExplainIncompleteKabeLeavesSequencePossible.
  ///
  /// In en, this message translates to:
  /// **'Three copies of the tile forming this incomplete kabe are publicly visible. The fourth may still be concealed, so the sequence route is not fully removed.'**
  String get defenseExplainIncompleteKabeLeavesSequencePossible;

  /// No description provided for @defenseExplainThreeVisibleHonorHasKokushiException.
  ///
  /// In en, this message translates to:
  /// **'Three public copies plus your candidate account for all four copies. Ordinary pair waits are unavailable, but a Thirteen Orphans wait for that honor can still win by ron.'**
  String get defenseExplainThreeVisibleHonorHasKokushiException;

  /// No description provided for @defenseExplainTwoVisibleHonorStillNotSafe.
  ///
  /// In en, this message translates to:
  /// **'With two public copies and the candidate in your hand, another copy can still be concealed. Tanki or special-hand waits remain possible.'**
  String get defenseExplainTwoVisibleHonorStillNotSafe;

  /// No description provided for @defenseExplainCombinedSujiAndKabeStillNotAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Suji and a complete kabe independently reduce ordinary sequence paths, but they do not prove safety against pair or special-hand waits.'**
  String get defenseExplainCombinedSujiAndKabeStillNotAbsolute;

  /// No description provided for @defenseExplainTargetGenbutsuOutranksRelativeClues.
  ///
  /// In en, this message translates to:
  /// **'The target\'s own discard is conclusive against that target\'s ron. Relative suji, kabe, and honor clues are not substitutes for genbutsu.'**
  String get defenseExplainTargetGenbutsuOutranksRelativeClues;

  /// No description provided for @defenseExplainNoEstablishedSafetyEvidence.
  ///
  /// In en, this message translates to:
  /// **'This lesson finds no genbutsu, suji, kabe, or visible-honor evidence that lowers this tile\'s risk against the target.'**
  String get defenseExplainNoEstablishedSafetyEvidence;

  /// No description provided for @defenseNext.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get defenseNext;

  /// No description provided for @defenseViewSummary.
  ///
  /// In en, this message translates to:
  /// **'View Results'**
  String get defenseViewSummary;

  /// No description provided for @defenseSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Complete'**
  String get defenseSummaryTitle;

  /// No description provided for @defenseSummaryScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} decisions matched the lesson.'**
  String defenseSummaryScore(int correct, int total);

  /// No description provided for @defenseSummaryAccuracy.
  ///
  /// In en, this message translates to:
  /// **'{accuracy}% accuracy'**
  String defenseSummaryAccuracy(int accuracy);

  /// No description provided for @defenseSummaryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'SKILL BREAKDOWN'**
  String get defenseSummaryBreakdown;

  /// No description provided for @defenseSummaryTopicScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} / {total}'**
  String defenseSummaryTopicScore(int correct, int total);

  /// No description provided for @defenseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get defenseTryAgain;

  /// No description provided for @defenseReviewDone.
  ///
  /// In en, this message translates to:
  /// **'Finish Review'**
  String get defenseReviewDone;

  /// No description provided for @defenseDone.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get defenseDone;

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

  /// No description provided for @leaderboardMyRank.
  ///
  /// In en, this message translates to:
  /// **'My Rank'**
  String get leaderboardMyRank;

  /// No description provided for @leaderboardNotRanked.
  ///
  /// In en, this message translates to:
  /// **'Play games to earn your rank!'**
  String get leaderboardNotRanked;

  /// No description provided for @leaderboardEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Name'**
  String get leaderboardEnterName;

  /// No description provided for @leaderboardNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get leaderboardNameHint;

  /// No description provided for @leaderboardSaveName.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get leaderboardSaveName;

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

  /// No description provided for @flashcardClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get flashcardClose;

  /// No description provided for @flashcardTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap tile to see mnemonic'**
  String get flashcardTapHint;

  /// No description provided for @flashcardAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get flashcardAccuracy;

  /// No description provided for @nanikiruNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Nani-Kiru · Tile Efficiency'**
  String get nanikiruNavTitle;

  /// No description provided for @nanikiruDiscardHint.
  ///
  /// In en, this message translates to:
  /// **'Discard 1 tile for max efficiency'**
  String get nanikiruDiscardHint;

  /// No description provided for @nanikiruEfficiencyScope.
  ///
  /// In en, this message translates to:
  /// **'Pure tile efficiency: ignores dora, yaku, score, round state, and defense.'**
  String get nanikiruEfficiencyScope;

  /// No description provided for @nanikiruGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get nanikiruGotIt;

  /// No description provided for @nanikiruAcceptanceGridTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Tiles'**
  String get nanikiruAcceptanceGridTitle;

  /// No description provided for @collectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Yaku Collection'**
  String get collectionTitle;

  /// No description provided for @collectionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get collectionClose;

  /// No description provided for @collectionMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get collectionMastery;

  /// No description provided for @tileBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Tile Browser'**
  String get tileBrowserTitle;

  /// No description provided for @tileBrowserClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tileBrowserClose;

  /// No description provided for @tileBrowserError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get tileBrowserError;

  /// No description provided for @commonGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonGoBack;

  /// No description provided for @commonNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get commonNotFound;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Profile'**
  String get profileTitle;

  /// No description provided for @profileLocalProgress.
  ///
  /// In en, this message translates to:
  /// **'Your learning progress is stored on this device.'**
  String get profileLocalProgress;

  /// No description provided for @profileElo.
  ///
  /// In en, this message translates to:
  /// **'Skill rating'**
  String get profileElo;

  /// No description provided for @profileLearningStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get profileLearningStreak;

  /// No description provided for @profileBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get profileBestStreak;

  /// No description provided for @profileLearningSection.
  ///
  /// In en, this message translates to:
  /// **'Learning progress'**
  String get profileLearningSection;

  /// No description provided for @profileTodayPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan'**
  String get profileTodayPlan;

  /// No description provided for @profileTodayProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} activities completed'**
  String profileTodayProgress(int current, int total);

  /// No description provided for @profileReviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get profileReviewQueue;

  /// No description provided for @profileReviewDue.
  ///
  /// In en, this message translates to:
  /// **'{count} due today'**
  String profileReviewDue(int count);

  /// No description provided for @profileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Previous purchases'**
  String get profileAccountSection;

  /// No description provided for @profilePreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferencesSection;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Language, purchase restore, privacy, and terms'**
  String get profileSettingsDesc;

  /// No description provided for @leaderboardKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing to climb the ranks!'**
  String get leaderboardKeepPlaying;

  /// No description provided for @leaderboardChangeName.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get leaderboardChangeName;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Leaderboard'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Your scores will be uploaded to the global leaderboard. Your display name will be visible to other players. You can change your name anytime in the leaderboard.\n\nNo other personal data is collected. See our Privacy Policy for details.'**
  String get consentBody;

  /// No description provided for @consentAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get consentAllow;

  /// No description provided for @consentNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get consentNotNow;

  /// No description provided for @flashcardSuitAll.
  ///
  /// In en, this message translates to:
  /// **'🎴 All'**
  String get flashcardSuitAll;

  /// No description provided for @flashcardSuitMan.
  ///
  /// In en, this message translates to:
  /// **'🀇 Man'**
  String get flashcardSuitMan;

  /// No description provided for @flashcardSuitPin.
  ///
  /// In en, this message translates to:
  /// **'🀙 Pin'**
  String get flashcardSuitPin;

  /// No description provided for @flashcardSuitSou.
  ///
  /// In en, this message translates to:
  /// **'🀐 Sou'**
  String get flashcardSuitSou;

  /// No description provided for @flashcardSuitHonor.
  ///
  /// In en, this message translates to:
  /// **'🀀 Honor'**
  String get flashcardSuitHonor;

  /// No description provided for @flashcardAllTiles.
  ///
  /// In en, this message translates to:
  /// **'All Tiles'**
  String get flashcardAllTiles;

  /// No description provided for @flashcardSuiteFormat.
  ///
  /// In en, this message translates to:
  /// **'{suite} Flashcards'**
  String flashcardSuiteFormat(Object suite);

  /// No description provided for @flashcardStudyHint.
  ///
  /// In en, this message translates to:
  /// **'📖 Study the mnemonic to remember this tile'**
  String get flashcardStudyHint;

  /// No description provided for @flashcardFinishedStats.
  ///
  /// In en, this message translates to:
  /// **'✅ {correct} correct · ❌ {wrong} wrong'**
  String flashcardFinishedStats(Object correct, Object wrong);

  /// No description provided for @nanikiruNew.
  ///
  /// In en, this message translates to:
  /// **'NEW!'**
  String get nanikiruNew;

  /// No description provided for @nanikiruDecision.
  ///
  /// In en, this message translates to:
  /// **'⏱ Decision: '**
  String get nanikiruDecision;

  /// No description provided for @nanikiruHandLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR HAND · 14 TILES'**
  String get nanikiruHandLabel;

  /// No description provided for @nanikiruSort.
  ///
  /// In en, this message translates to:
  /// **'📐 Sort'**
  String get nanikiruSort;

  /// No description provided for @nanikiruHintTitle.
  ///
  /// In en, this message translates to:
  /// **'💡 Hint'**
  String get nanikiruHintTitle;

  /// No description provided for @nanikiruSessionCount.
  ///
  /// In en, this message translates to:
  /// **'⚔{count}'**
  String nanikiruSessionCount(Object count);

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get leaderboardYou;

  /// No description provided for @leaderboardStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} streak'**
  String leaderboardStreak(Object count);

  /// No description provided for @leaderboardElo.
  ///
  /// In en, this message translates to:
  /// **'{elo} ELO'**
  String leaderboardElo(Object elo);

  /// No description provided for @settingsLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get settingsLearning;

  /// No description provided for @settingsDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get settingsDailyGoal;

  /// No description provided for @settingsCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get settingsCountdown;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settingsSignIn;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsComingSoon;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersionLabel;

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

  /// No description provided for @graveyardSrsReview.
  ///
  /// In en, this message translates to:
  /// **'SRS Review'**
  String get graveyardSrsReview;

  /// No description provided for @graveyardTodaysReview.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S REVIEW'**
  String get graveyardTodaysReview;

  /// No description provided for @graveyardReviewAll.
  ///
  /// In en, this message translates to:
  /// **'⚡ Review All ({count})'**
  String graveyardReviewAll(int count);

  /// No description provided for @graveyardWeaknessRadar.
  ///
  /// In en, this message translates to:
  /// **'Weakness Radar'**
  String get graveyardWeaknessRadar;

  /// No description provided for @graveyardWeakest.
  ///
  /// In en, this message translates to:
  /// **'⚠ Weakest: {suit} ({rate}% error rate)'**
  String graveyardWeakest(Object suit, Object rate);

  /// No description provided for @graveyardNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing due!\nAll caught up.'**
  String get graveyardNothingDue;

  /// No description provided for @graveyardErrorsOverdue.
  ///
  /// In en, this message translates to:
  /// **'{errors} errors · {days}d overdue'**
  String graveyardErrorsOverdue(Object errors, Object days);

  /// No description provided for @graveyardDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} DUE'**
  String graveyardDueCount(int count);

  /// No description provided for @yakuQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Yaku Dojo'**
  String get yakuQuizTitle;

  /// No description provided for @yakuQuizSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge of yaku and scoring.'**
  String get yakuQuizSubtitle;

  /// No description provided for @yakuQuizProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String yakuQuizProgress(int current, int total);

  /// No description provided for @yakuQuizCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get yakuQuizCorrect;

  /// No description provided for @yakuQuizIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get yakuQuizIncorrect;

  /// No description provided for @yakuQuizExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get yakuQuizExplanation;

  /// No description provided for @yakuQuizNext.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get yakuQuizNext;

  /// No description provided for @yakuQuizFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get yakuQuizFinish;

  /// No description provided for @yakuQuizSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Complete'**
  String get yakuQuizSummaryTitle;

  /// No description provided for @yakuQuizSummaryBody.
  ///
  /// In en, this message translates to:
  /// **'You answered {correct} of {total} correctly.\nAccuracy: {accuracy}%'**
  String yakuQuizSummaryBody(int correct, int total, int accuracy);

  /// No description provided for @yakuQuizTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get yakuQuizTryAgain;

  /// No description provided for @yakuQuizTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get yakuQuizTrue;

  /// No description provided for @yakuQuizFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get yakuQuizFalse;

  /// No description provided for @yakuQuizHanOption.
  ///
  /// In en, this message translates to:
  /// **'{han} Han'**
  String yakuQuizHanOption(int han);

  /// No description provided for @yakuQuizStart.
  ///
  /// In en, this message translates to:
  /// **'Start Training'**
  String get yakuQuizStart;

  /// No description provided for @yakuQuizTestMe.
  ///
  /// In en, this message translates to:
  /// **'Test Me'**
  String get yakuQuizTestMe;

  /// No description provided for @yakuQuizReviewDone.
  ///
  /// In en, this message translates to:
  /// **'Finish Review'**
  String get yakuQuizReviewDone;

  /// No description provided for @yakuDetailClosedHan.
  ///
  /// In en, this message translates to:
  /// **'{han} Han · closed only'**
  String yakuDetailClosedHan(int han);

  /// No description provided for @yakuDetailClosedOpenHan.
  ///
  /// In en, this message translates to:
  /// **'{closed} Han closed · {open} Han open'**
  String yakuDetailClosedOpenHan(int closed, int open);

  /// No description provided for @yakuQuizPromptRiichiDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku is declared in tenpai with a closed hand after placing a 1,000-point stick?'**
  String get yakuQuizPromptRiichiDefinition;

  /// No description provided for @yakuQuizExplanationRiichiDefinition.
  ///
  /// In en, this message translates to:
  /// **'Riichi is declared while in tenpai with a closed hand and is worth 1 han.'**
  String get yakuQuizExplanationRiichiDefinition;

  /// No description provided for @yakuQuizPromptTanyaoDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku uses only numbered tiles 2–8, excluding terminals and honors?'**
  String get yakuQuizPromptTanyaoDefinition;

  /// No description provided for @yakuQuizExplanationTanyaoDefinition.
  ///
  /// In en, this message translates to:
  /// **'Tanyao uses only numbered tiles 2–8, with no terminals or honors.'**
  String get yakuQuizExplanationTanyaoDefinition;

  /// No description provided for @yakuQuizPromptPinfuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku requires a closed all-sequence hand, a non-value pair, and a two-sided wait?'**
  String get yakuQuizPromptPinfuDefinition;

  /// No description provided for @yakuQuizExplanationPinfuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Pinfu is a closed hand of sequences with a non-value pair and a two-sided wait.'**
  String get yakuQuizExplanationPinfuDefinition;

  /// No description provided for @yakuQuizPromptYakuhaiDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku is earned from a triplet or quad of dragons, the round wind, or the player\'s seat wind?'**
  String get yakuQuizPromptYakuhaiDefinition;

  /// No description provided for @yakuQuizExplanationYakuhaiDefinition.
  ///
  /// In en, this message translates to:
  /// **'A triplet or quad of dragons, the round wind, or the player\'s seat wind is worth 1 han.'**
  String get yakuQuizExplanationYakuhaiDefinition;

  /// No description provided for @yakuQuizPromptIipeikouDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku uses two identical sequences in the same suit in a closed hand?'**
  String get yakuQuizPromptIipeikouDefinition;

  /// No description provided for @yakuQuizExplanationIipeikouDefinition.
  ///
  /// In en, this message translates to:
  /// **'Iipeikou is two identical sequences in the same suit in a closed hand.'**
  String get yakuQuizExplanationIipeikouDefinition;

  /// No description provided for @yakuQuizPromptChitoitsuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku is a closed hand made from seven distinct pairs?'**
  String get yakuQuizPromptChitoitsuDefinition;

  /// No description provided for @yakuQuizExplanationChitoitsuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Chitoitsu is a closed hand of seven distinct pairs and is worth 2 han.'**
  String get yakuQuizExplanationChitoitsuDefinition;

  /// No description provided for @yakuQuizPromptToitoiDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku consists of four triplets or quads and a pair?'**
  String get yakuQuizPromptToitoiDefinition;

  /// No description provided for @yakuQuizExplanationToitoiDefinition.
  ///
  /// In en, this message translates to:
  /// **'Toitoi consists of four triplets or quads and a pair; it is worth 2 han whether open or closed.'**
  String get yakuQuizExplanationToitoiDefinition;

  /// No description provided for @yakuQuizPromptSanshokuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku uses the same sequence in all three numbered suits?'**
  String get yakuQuizPromptSanshokuDefinition;

  /// No description provided for @yakuQuizExplanationSanshokuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Sanshoku Doujun uses the same sequence in all three suits and is worth 2 han closed or 1 han open.'**
  String get yakuQuizExplanationSanshokuDefinition;

  /// No description provided for @yakuQuizPromptIkkitsukanDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku combines 1-2-3, 4-5-6, and 7-8-9 in one suit?'**
  String get yakuQuizPromptIkkitsukanDefinition;

  /// No description provided for @yakuQuizExplanationIkkitsukanDefinition.
  ///
  /// In en, this message translates to:
  /// **'Ikkitsukan combines 1-2-3, 4-5-6, and 7-8-9 in one suit; it is worth 2 han closed or 1 han open.'**
  String get yakuQuizExplanationIkkitsukanDefinition;

  /// No description provided for @yakuQuizPromptHonitsuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku uses one numbered suit together with honor tiles?'**
  String get yakuQuizPromptHonitsuDefinition;

  /// No description provided for @yakuQuizExplanationHonitsuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Honitsu uses one numbered suit plus honors and is worth 3 han closed or 2 han open.'**
  String get yakuQuizExplanationHonitsuDefinition;

  /// No description provided for @yakuQuizPromptChinitsuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Which yaku uses only one numbered suit and no honor tiles?'**
  String get yakuQuizPromptChinitsuDefinition;

  /// No description provided for @yakuQuizExplanationChinitsuDefinition.
  ///
  /// In en, this message translates to:
  /// **'Chinitsu uses only one numbered suit with no honors and is worth 6 han closed or 5 han open.'**
  String get yakuQuizExplanationChinitsuDefinition;

  /// No description provided for @yakuQuizPromptHonitsuOpenHan.
  ///
  /// In en, this message translates to:
  /// **'What is Honitsu worth when the hand is open?'**
  String get yakuQuizPromptHonitsuOpenHan;

  /// No description provided for @yakuQuizExplanationHonitsuOpenHan.
  ///
  /// In en, this message translates to:
  /// **'An open Honitsu is worth 2 han; a closed Honitsu is worth 3 han.'**
  String get yakuQuizExplanationHonitsuOpenHan;

  /// No description provided for @yakuQuizPromptChinitsuOpenHan.
  ///
  /// In en, this message translates to:
  /// **'What is Chinitsu worth when the hand is open?'**
  String get yakuQuizPromptChinitsuOpenHan;

  /// No description provided for @yakuQuizExplanationChinitsuOpenHan.
  ///
  /// In en, this message translates to:
  /// **'An open Chinitsu is worth 5 han; a closed Chinitsu is worth 6 han.'**
  String get yakuQuizExplanationChinitsuOpenHan;

  /// No description provided for @yakuQuizPromptSanshokuOpenHan.
  ///
  /// In en, this message translates to:
  /// **'What is Sanshoku Doujun worth when the hand is open?'**
  String get yakuQuizPromptSanshokuOpenHan;

  /// No description provided for @yakuQuizExplanationSanshokuOpenHan.
  ///
  /// In en, this message translates to:
  /// **'An open Sanshoku Doujun is worth 1 han; a closed one is worth 2 han.'**
  String get yakuQuizExplanationSanshokuOpenHan;

  /// No description provided for @yakuQuizPromptJunchanClosedHan.
  ///
  /// In en, this message translates to:
  /// **'What is Junchan worth with a closed hand?'**
  String get yakuQuizPromptJunchanClosedHan;

  /// No description provided for @yakuQuizExplanationJunchanClosedHan.
  ///
  /// In en, this message translates to:
  /// **'A closed Junchan is worth 3 han; an open Junchan is worth 2 han.'**
  String get yakuQuizExplanationJunchanClosedHan;

  /// No description provided for @yakuQuizPromptDoraIsYaku.
  ///
  /// In en, this message translates to:
  /// **'Can dora alone satisfy the yaku requirement for winning?'**
  String get yakuQuizPromptDoraIsYaku;

  /// No description provided for @yakuQuizExplanationDoraIsYaku.
  ///
  /// In en, this message translates to:
  /// **'Dora add han but are not yaku. The hand still needs at least one valid yaku to win.'**
  String get yakuQuizExplanationDoraIsYaku;

  /// No description provided for @yakuQuizPromptPinfuClosedOnly.
  ///
  /// In en, this message translates to:
  /// **'Can Pinfu be completed with an open hand?'**
  String get yakuQuizPromptPinfuClosedOnly;

  /// No description provided for @yakuQuizExplanationPinfuClosedOnly.
  ///
  /// In en, this message translates to:
  /// **'No. Pinfu is a closed-hand-only yaku.'**
  String get yakuQuizExplanationPinfuClosedOnly;

  /// No description provided for @yakuQuizPromptTanyaoAllowsHonors.
  ///
  /// In en, this message translates to:
  /// **'Can a Tanyao hand contain honor tiles?'**
  String get yakuQuizPromptTanyaoAllowsHonors;

  /// No description provided for @yakuQuizExplanationTanyaoAllowsHonors.
  ///
  /// In en, this message translates to:
  /// **'No. Tanyao allows only numbered tiles 2–8, so honors and terminals are excluded.'**
  String get yakuQuizExplanationTanyaoAllowsHonors;
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
