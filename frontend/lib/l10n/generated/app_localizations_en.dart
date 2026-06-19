// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TileSlash';

  @override
  String get appTagline => 'Master Mahjong, One Tile at a Time';

  @override
  String get onboarding1Title => 'Master Tile\nRecognition';

  @override
  String get onboarding1Desc =>
      '4-choice flashcard quiz for all 34 tiles.\nCorrect = use a heart.\nWrong = review free forever.';

  @override
  String get onboarding2Title => 'Train Tile\nEfficiency';

  @override
  String get onboarding2Desc =>
      'Draw a tile, then choose the\noptimal discard from your hand.\nPerfect answers get visual rewards.';

  @override
  String get onboarding3Title => 'Start Free';

  @override
  String get onboarding3Desc =>
      'No sign-up required.\n10 free puzzles every day.\nUnlock unlimited with Pro.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get homeDailyChallenge => 'DAILY CHALLENGE';

  @override
  String get homeDailyDesc =>
      '3 puzzles. No stamina cost. Claim your daily reward.';

  @override
  String get homeStartChallenge => '⚡ START CHALLENGE';

  @override
  String get homeQuickAccess => 'QUICK ACCESS';

  @override
  String get homeFlashcards => 'Flashcards';

  @override
  String get homeNanikiru => 'Nani-Kiru';

  @override
  String get homeScanner => 'Scanner';

  @override
  String get homeCollection => 'Yaku Guide';

  @override
  String get homeGraveyard => 'Graveyard';

  @override
  String get homeTileBrowser => 'Tile Browser';

  @override
  String get homeProfile => 'Profile';

  @override
  String get homePremium => 'Premium';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeRank => 'Rank';

  @override
  String get homeUpgrade => 'UPGRADE';

  @override
  String get homePro => 'PRO';

  @override
  String homeFreeCount(int count) {
    return '$count/3 free';
  }

  @override
  String get battleTitle => 'Today\'s Battle Report';

  @override
  String get battleTotal => 'Total';

  @override
  String get battleAccuracy => 'Accuracy';

  @override
  String get battleMaxCombo => 'Max Combo';

  @override
  String get battleMistakeHint => 'Review mistakes anytime — free, no limits';

  @override
  String get battlePremiumCTA => '\$4.99/mo  —  Unlimited Play';

  @override
  String get battleMistakes => 'Review Past Mistakes';

  @override
  String get battleShare => 'Share';

  @override
  String get battleInvite => 'Invite';

  @override
  String get battleMistakesBtn => 'Mistakes';

  @override
  String get battleComboBanner => 'COMBO ×10!';

  @override
  String get battleComboSub => 'Annual 20% OFF — \$23.99/yr';

  @override
  String get battleComboUnlock => 'UNLOCK';

  @override
  String get battleDomain => 'tilezhan.app';

  @override
  String get premiumTitle => 'Choose Your Plan';

  @override
  String get premiumConnecting => 'Connecting to App Store...';

  @override
  String get premiumContinue => 'CONTINUE';

  @override
  String get premiumSelectPlan => 'SELECT A PLAN';

  @override
  String get premiumPurchasing => 'PURCHASING...';

  @override
  String get premiumRestore => 'Restore Purchases';

  @override
  String get premiumAllPlansHeader => 'All paid plans include:';

  @override
  String get premiumAllPlansFooter =>
      '✅ Unlimited puzzle replay   ✅ Ghost Mode (mistake review)   ✅ Cancel anytime';

  @override
  String get premiumFree => 'FREE';

  @override
  String get premiumMonthly => 'MONTHLY';

  @override
  String get premiumAnnual => 'ANNUAL';

  @override
  String get premiumLifetime => 'LIFETIME';

  @override
  String get premiumPopular => '★ POPULAR';

  @override
  String get premiumBestValue => 'BEST VALUE — Save 50%';

  @override
  String get premiumPayOnce => 'PAY ONCE';

  @override
  String get premiumLaunchBanner =>
      'Launch Special: Lifetime 20% OFF — Limited Time';

  @override
  String get premiumPrivacy => 'Privacy Policy';

  @override
  String get premiumTerms => 'Terms of Use';

  @override
  String shareStats(Object total, Object accuracy, Object combo) {
    return '🎯 $total puzzles today · $accuracy% accuracy · $combo× max combo on TileZhan! tilezhan.app';
  }

  @override
  String get inviteText =>
      '🀄 Join me on TileZhan — master Mahjong tile recognition! Free daily puzzles. Get it at tilezhan.app';

  @override
  String get comboTitle => 'COMBO ×10!';

  @override
  String get comboSubtitle =>
      'You\'re on fire! Unlock unlimited play\nand keep your streak alive.';

  @override
  String get comboOffer => 'SPECIAL OFFER';

  @override
  String get comboDiscount => '20% OFF';

  @override
  String get comboUnlock => 'UNLOCK NOW — \$23.99';

  @override
  String get comboMaybe => 'Maybe later';

  @override
  String get nanikiruDraw => 'You just drew:';

  @override
  String nanikiruCorrect(Object discard) {
    return 'Correct discard: $discard';
  }

  @override
  String nanikiruYourDiscard(Object discard) {
    return 'Your discard: $discard';
  }

  @override
  String nanikiruBestDiscard(Object discard, Object count, Object types) {
    return 'Best discard: $discard  →  $count tile types, $types acceptance tiles';
  }

  @override
  String get nanikiruPerfectExplain =>
      'Maximizing tile acceptance — this discard gives you the most ways to complete your hand.';

  @override
  String get nanikiruHint =>
      'Look for sequences and triplets.\nDiscard isolated tiles that don\'t form any meld.\nThe correct answer maximizes tile acceptance (ukeire).';

  @override
  String get nanikiruSkip => '🏳️ Skip';

  @override
  String get nanikiruConfirm => 'Confirm';

  @override
  String get nanikiruTapToContinue => 'Tap anywhere to continue';

  @override
  String get nanikiruPerfect => '🎯 PERFECT!';

  @override
  String get nanikiruBlunder => '💥 BLUNDER!';

  @override
  String get nanikiruAcceptanceTiles => 'Acceptance Tiles';

  @override
  String get nanikiruNextPuzzle => 'Next Puzzle';

  @override
  String get nanikiruReviewAgain => 'Review Again';

  @override
  String get nanikiruAcceptanceComparison => 'Acceptance Comparison';

  @override
  String get nanikiruYourDiscardLabel => 'Your discard';

  @override
  String get nanikiruBestDiscardLabel => 'Best discard';

  @override
  String get scannerTitle => 'Yaku Scanner';

  @override
  String get scannerDesc =>
      'Full hand scanning coming in V2.\nBrowse all 10 basic yaku below.';

  @override
  String get scannerBasicYaku => 'BASIC YAKU';

  @override
  String get scannerFavorites => 'FAVORITES';

  @override
  String get scannerBeginner => 'Beginner';

  @override
  String get scannerIntermediate => 'Intermediate';

  @override
  String get scannerAdvanced => 'Advanced';

  @override
  String get scannerYakuman => 'Yakuman';

  @override
  String scannerYakuCount(int count) {
    return '$count yaku';
  }

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardEmpty => 'Be the first to rank!';

  @override
  String get leaderboardEmptySub => 'Complete puzzles to earn your spot.';

  @override
  String get leaderboardRetry => 'Retry';

  @override
  String get leaderboardMyRank => 'My Rank';

  @override
  String get leaderboardNotRanked => 'Play games to earn your rank!';

  @override
  String get leaderboardEnterName => 'Enter Your Name';

  @override
  String get leaderboardNameHint => 'Your display name';

  @override
  String get leaderboardSaveName => 'Save';

  @override
  String get flashcardTimer => 's';

  @override
  String get flashcardPerfect => 'Perfect!';

  @override
  String get flashcardCorrect => 'Correct';

  @override
  String get flashcardIncorrect => 'Incorrect';

  @override
  String get flashcardTimeout => 'Timeout';

  @override
  String get flashcardPlayAgain => '🔄 Play Again';

  @override
  String get flashcardGotIt => 'Got it ✓';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAnimation => 'Animation Speed';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version 1.0.0';

  @override
  String get rankNovice => 'Novice';

  @override
  String get rankApprentice => 'Apprentice';

  @override
  String get rankAdept => 'Adept';

  @override
  String get rankExpert => 'Expert';

  @override
  String get rankMaster => 'Master';

  @override
  String rankReviews(Object count) {
    return '$count reviews';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navTiles => 'Tiles';

  @override
  String get navYaku => 'Yaku';

  @override
  String get navReview => 'Review';
}
