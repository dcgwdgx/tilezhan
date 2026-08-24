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
      '4-choice flashcard quiz for all 34 tiles.\nCorrect answers are always free.\nMistakes enter your review queue.';

  @override
  String get onboarding2Title => 'Train Tile\nEfficiency';

  @override
  String get onboarding2Desc =>
      'Draw a tile, then choose the\noptimal discard from your hand.\nPerfect answers get visual rewards.';

  @override
  String get onboarding3Title => 'Build a Daily\nLearning Habit';

  @override
  String get onboarding3Desc =>
      'Follow a short plan tailored to your reviews and recent practice.\nNo sign-up required. All training is free in this version.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start First Lesson';

  @override
  String get homeDailyChallenge => 'DAILY CHALLENGE';

  @override
  String get homeDailyDesc =>
      'Complete 3 tile-efficiency puzzles with no stamina cost and build your daily streak.';

  @override
  String get homeStartChallenge => '⚡ START CHALLENGE';

  @override
  String get homeQuickAccess => 'QUICK ACCESS';

  @override
  String get homeFlashcards => 'Flashcards';

  @override
  String get homeNanikiru => 'Nani-Kiru';

  @override
  String get homeDefenseTraining => 'Defense Trainer';

  @override
  String get homeScanner => 'Yaku Reference';

  @override
  String get homeHandAnalyzer => 'Hand Analyzer';

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
  String homeHeartsRemaining(int count) {
    return '$count hearts remaining';
  }

  @override
  String dailyStreak(int count) {
    return '🔥 $count-day streak';
  }

  @override
  String dailyProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get dailyViewResult => 'VIEW TODAY\'S RESULT';

  @override
  String get dailySummaryTitle => 'Daily Challenge Complete';

  @override
  String dailySummaryBody(int correct, int total, int accuracy, int streak) {
    return 'You solved $correct/$total puzzles correctly.\nAccuracy: $accuracy%\nLearning streak: $streak days';
  }

  @override
  String get trainingLoading => 'Preparing today\'s plan...';

  @override
  String get trainingLoadError =>
      'Today\'s plan could not be loaded. You can retry without losing saved progress.';

  @override
  String get trainingRetry => 'RETRY PLAN';

  @override
  String get trainingSaveError =>
      'Your progress could not be saved. Check device storage, then try again.';

  @override
  String get trainingSaveRetry => 'RETRY SAVE';

  @override
  String get trainingTodayTitle => 'Today\'s 5-minute plan';

  @override
  String get trainingTodaySubtitle =>
      'A focused path based on your reviews and recent practice.';

  @override
  String trainingPlanProgress(int current, int total) {
    return '$current/$total completed';
  }

  @override
  String get trainingStreakStart => 'Start your learning streak';

  @override
  String trainingLearningStreak(int count) {
    return '🔥 $count-day learning streak';
  }

  @override
  String get trainingPlanComplete => 'PLAN COMPLETE';

  @override
  String get trainingStartPlan => 'START TODAY\'S PLAN';

  @override
  String get trainingContinuePlan => 'CONTINUE PLAN';

  @override
  String get trainingTaskStarterTiles => 'Learn the core tiles';

  @override
  String get trainingTaskDueReview => 'Clear today\'s reviews';

  @override
  String trainingTaskWeakSkill(String skill) {
    return 'Strengthen $skill';
  }

  @override
  String get trainingTaskDailyEfficiency => 'Daily efficiency challenge';

  @override
  String get trainingTaskExploreDefense => 'Explore defensive reading';

  @override
  String get trainingTaskExploreYaku => 'Explore yaku knowledge';

  @override
  String get trainingTaskStarterDesc =>
      'Build instant recognition with three quick flashcards.';

  @override
  String trainingTaskDueDesc(int count) {
    return 'Review $count item(s) scheduled for today.';
  }

  @override
  String get trainingTaskDailyDesc =>
      'Make three discard decisions and compare tile efficiency.';

  @override
  String get trainingTaskExploreDefenseDesc =>
      'Learn to rank safe discards from visible evidence.';

  @override
  String get trainingTaskExploreYakuDesc =>
      'Check the definitions and rules that make a winning hand valid.';

  @override
  String get trainingTaskWeakDesc =>
      'Practice focused questions selected from this weak area.';

  @override
  String trainingTaskWeakEvidence(int correct, int attempts) {
    return 'Recent evidence: $correct/$attempts correct';
  }

  @override
  String get trainingSkillIsolatedTiles => 'isolated-tile choices';

  @override
  String get trainingSkillTaatsuOverload => 'overloaded shapes';

  @override
  String get trainingSkillPairProtection => 'pair protection';

  @override
  String get trainingSkillChiitoitsuChoice => 'seven-pairs decisions';

  @override
  String get trainingSkillKokushiShape => 'thirteen-orphans shapes';

  @override
  String get trainingSkillTileEfficiency => 'tile efficiency';

  @override
  String get trainingSkillGeneral => 'recent weak areas';

  @override
  String get dailySummaryDone => 'Done';

  @override
  String get reviewFinish => 'Finish Review';

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
  String get battlePremiumCTA => 'View Premium Options';

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
  String get battleComboSub => 'See the plans currently available in the store';

  @override
  String get battleComboUnlock => 'VIEW OPTIONS';

  @override
  String get battleDomain => 'tilezhan.app';

  @override
  String get premiumTitle => 'Choose Your Plan';

  @override
  String get premiumConnecting => 'Connecting to the store...';

  @override
  String get premiumContinue => 'CONTINUE';

  @override
  String get premiumSelectPlan => 'SELECT A PLAN';

  @override
  String get premiumPurchasing => 'PURCHASING...';

  @override
  String get premiumRestore => 'Restore Purchases';

  @override
  String get premiumFreeReleaseTitle => 'All training is free in this version';

  @override
  String get premiumFreeReleaseBody =>
      'Practice without stamina or difficulty limits. Your results and mistake reviews remain available.';

  @override
  String get premiumRestoreHint =>
      'Already purchased in an earlier version? Restore your purchase history here.';

  @override
  String get premiumRestoring => 'RESTORING...';

  @override
  String get premiumRestoreRequested =>
      'Restore request sent. Your access will update after the store confirms it.';

  @override
  String get premiumRestoreFailed =>
      'Purchases could not be restored. Please try again.';

  @override
  String get premiumNoProducts =>
      'Purchases are temporarily unavailable. No store products are currently offered.';

  @override
  String get premiumUnavailable =>
      'The store is temporarily unavailable. Please try again later.';

  @override
  String get premiumRetry => 'TRY AGAIN';

  @override
  String get premiumPurchaseStarted =>
      'Purchase request sent. Follow the store prompts to finish.';

  @override
  String get premiumPurchaseFailed =>
      'The purchase could not be started. Please try again.';

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
    return 'Best discard: $discard  →  $types types, $count acceptance tiles';
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
  String get nanikiruSkippedTitle => 'SKIPPED';

  @override
  String get nanikiruTimedOutTitle => 'TIME\'S UP!';

  @override
  String get nanikiruTopCandidatesTitle => 'Top discard candidates';

  @override
  String get nanikiruBestBadge => 'BEST';

  @override
  String get nanikiruSelectedBadge => 'YOUR CHOICE';

  @override
  String get nanikiruTenpai => 'Tenpai';

  @override
  String nanikiruShantenValue(int shanten) {
    return '$shanten-shanten';
  }

  @override
  String nanikiruAcceptanceSummary(int types, int count) {
    return 'Types: $types · Tiles: $count';
  }

  @override
  String nanikiruUkeireLoss(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fewer acceptance tiles than the best discard',
      one: '1 fewer acceptance tile than the best discard',
    );
    return '$_temp0';
  }

  @override
  String nanikiruShantenLoss(int shanten) {
    return 'Falls back by $shanten shanten';
  }

  @override
  String get nanikiruNoSelection => 'No tile selected';

  @override
  String nanikiruTimeoutChoice(String discard) {
    return 'Choice when time expired: $discard';
  }

  @override
  String get nanikiruSkillsTitle => 'Skills trained';

  @override
  String get nanikiruTypesLabel => 'Types';

  @override
  String get nanikiruSkillIsolatedTile => 'Isolated tile handling';

  @override
  String get nanikiruSkillTaatsuOverload => 'Taatsu selection';

  @override
  String get nanikiruSkillPairProtection => 'Pair preservation';

  @override
  String get nanikiruSkillChiitoitsu => 'Seven Pairs path';

  @override
  String get nanikiruSkillKokushi => 'Thirteen Orphans path';

  @override
  String get nanikiruSkillGeneralEfficiency => 'Tile efficiency';

  @override
  String get nanikiruNotOptimalTitle => 'NOT OPTIMAL';

  @override
  String get nanikiruDecisionLossTitle => 'Decision impact';

  @override
  String get nanikiruNoDecisionLoss => 'Best choice — no efficiency loss';

  @override
  String nanikiruRankLabel(int rank) {
    return 'Rank #$rank';
  }

  @override
  String nanikiruDiscardLabel(String tile) {
    return 'Discard: $tile';
  }

  @override
  String get scannerTitle => 'Yaku Reference';

  @override
  String get scannerDesc =>
      'Browse the yaku reference below or open the Yaku Dojo to test your knowledge.';

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
  String get handAnalyzerTitle => 'Hand Analyzer';

  @override
  String get handAnalyzerSubtitle =>
      'Enter a closed 13- or 14-tile hand for exact tile-efficiency analysis.';

  @override
  String get handAnalyzerScope =>
      'Pure tile efficiency only. Dora, yaku, points, visible tiles, calls, and defense are not considered.';

  @override
  String get handAnalyzerHand => 'YOUR HAND';

  @override
  String handAnalyzerTileCount(int count, int target) {
    return '$count / $target tiles';
  }

  @override
  String get handAnalyzerNeedTileCount =>
      'Enter exactly 13 or 14 tiles to analyze.';

  @override
  String get handAnalyzerFourCopyLimit =>
      'A tile can appear at most four times.';

  @override
  String get handAnalyzerRemoveHint => 'Tap a tile in your hand to remove it.';

  @override
  String get handAnalyzerPicker => 'ADD TILES';

  @override
  String get handAnalyzerMan => 'Manzu';

  @override
  String get handAnalyzerPin => 'Pinzu';

  @override
  String get handAnalyzerSou => 'Souzu';

  @override
  String get handAnalyzerHonors => 'Honors';

  @override
  String get handAnalyzerAnalyze => 'Analyze Hand';

  @override
  String get handAnalyzerClear => 'Clear';

  @override
  String get handAnalyzerCurrentShanten => 'Current shanten';

  @override
  String get handAnalyzerComplete => 'Complete hand';

  @override
  String get handAnalyzerTenpai => 'Tenpai';

  @override
  String handAnalyzerShantenValue(int count) {
    return '$count-shanten';
  }

  @override
  String get handAnalyzerImprovingTiles => 'Improving tiles';

  @override
  String handAnalyzerEffectiveSummary(int types, int count) {
    return '$types types · $count tiles';
  }

  @override
  String get handAnalyzerDiscardCandidates => 'Discard candidates';

  @override
  String handAnalyzerCandidateSummary(String shanten, int types, int count) {
    return 'After discard: $shanten · $types types · $count tiles';
  }

  @override
  String get handAnalyzerBest => 'BEST';

  @override
  String handAnalyzerRank(int rank) {
    return '#$rank';
  }

  @override
  String get handAnalyzerNoImprovingTiles =>
      'No improving tiles for this state.';

  @override
  String get handAnalyzerSave => 'Save Analysis';

  @override
  String get handAnalyzerSaved => 'Saved to recent analyses.';

  @override
  String get handAnalyzerRecent => 'RECENT ANALYSES';

  @override
  String get handAnalyzerRecentEmpty => 'Saved hands will appear here.';

  @override
  String get handAnalyzerOpen => 'Open';

  @override
  String get handAnalyzerDelete => 'Delete';

  @override
  String get handAnalyzerShapeBreakdown => 'Shape breakdown';

  @override
  String get handAnalyzerStandard => 'Standard';

  @override
  String get handAnalyzerSevenPairs => 'Seven pairs';

  @override
  String get handAnalyzerThirteenOrphans => 'Thirteen orphans';

  @override
  String get handAnalyzerError =>
      'This hand could not be analyzed. Check the tile count and try again.';

  @override
  String get defenseTitle => 'Defense Trainer';

  @override
  String get defenseIntroTitle => 'Read the danger before you discard';

  @override
  String get defenseIntroBody =>
      'Practice choosing the lowest-risk tile against one riichi opponent using visible evidence.';

  @override
  String get defenseScope =>
      'Genbutsu is safe only against the target player. Suji, kabe, and visible honors can reduce some risks but never guarantee safety.';

  @override
  String defenseSessionLength(int count) {
    return '$count-question session';
  }

  @override
  String get defenseStart => 'Start Training';

  @override
  String defenseProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get defenseQuestionPrompt =>
      'Which discard has the lowest risk against the target player in this scenario?';

  @override
  String defenseTargetRiver(String seat) {
    return 'Riichi target river · $seat';
  }

  @override
  String defenseOtherRiver(String seat) {
    return 'Other river · $seat';
  }

  @override
  String get defenseAdditionalVisible => 'OTHER VISIBLE TILES';

  @override
  String defenseVisibleCopies(int count) {
    return '$count visible';
  }

  @override
  String defenseVisibleTileSemantics(String tile, int count) {
    return '$tile, $count visible copies';
  }

  @override
  String defenseTileSemantics(String tile) {
    return 'Tile $tile';
  }

  @override
  String defenseNumberedTile(int number, String suit) {
    return '$number of $suit';
  }

  @override
  String get defenseTileManSuit => 'characters';

  @override
  String get defenseTilePinSuit => 'circles';

  @override
  String get defenseTileSouSuit => 'bamboo';

  @override
  String get defenseTileEastWind => 'East Wind';

  @override
  String get defenseTileSouthWind => 'South Wind';

  @override
  String get defenseTileWestWind => 'West Wind';

  @override
  String get defenseTileNorthWind => 'North Wind';

  @override
  String get defenseTileRedDragon => 'Red Dragon';

  @override
  String get defenseTileGreenDragon => 'Green Dragon';

  @override
  String get defenseTileWhiteDragon => 'White Dragon';

  @override
  String get defenseChoicesTitle => 'CHOOSE A DISCARD';

  @override
  String defenseChooseTile(String tile) {
    return 'Choose $tile';
  }

  @override
  String get defenseLoadError => 'The defense lesson could not be loaded.';

  @override
  String get defenseRetry => 'Retry';

  @override
  String get defenseTopicGenbutsu => 'Genbutsu';

  @override
  String get defenseTopicSuji => 'Suji';

  @override
  String get defenseTopicKabe => 'Kabe';

  @override
  String get defenseTopicHonorVisibility => 'Visible honors';

  @override
  String get defenseTopicCombinedEvidence => 'Combined evidence';

  @override
  String get defenseSeatEast => 'East';

  @override
  String get defenseSeatSouth => 'South';

  @override
  String get defenseSeatWest => 'West';

  @override
  String get defenseSeatNorth => 'North';

  @override
  String get defenseGoodDecision => 'Good decision';

  @override
  String get defenseReviewChoice => 'Review this choice';

  @override
  String get defenseYourChoice => 'Your choice';

  @override
  String get defenseRecommendedChoice => 'Recommended choice';

  @override
  String get defenseSelected => 'SELECTED';

  @override
  String get defenseRecommended => 'RECOMMENDED';

  @override
  String get defenseEvidenceTitle => 'Defensive evidence';

  @override
  String get defenseRiskAbsoluteAgainstTarget =>
      'Safe against target · genbutsu';

  @override
  String get defenseRiskStronglyReducedNotAbsolute =>
      'Strongly reduced risk · not guaranteed safe';

  @override
  String get defenseRiskRelativelyReducedNotAbsolute =>
      'Lower-risk clue · not guaranteed safe';

  @override
  String get defenseRiskNoEstablishedReduction =>
      'No established risk reduction';

  @override
  String get defenseExplainTargetOwnDiscardIsGenbutsu =>
      'This tile appears in the target player\'s own river. Furiten prevents that player from winning by ron on the same tile; it says nothing about the other players.';

  @override
  String get defenseExplainOtherOpponentDiscardIsNotTargetGenbutsu =>
      'This tile appears only in another player\'s river, so it is not genbutsu against the target.';

  @override
  String get defenseExplainSujiCoversOnlyRyanmen =>
      'The target\'s river provides a suji clue that removes some two-sided sequence waits. Tanki, shanpon, edge, closed, and special-hand waits can remain.';

  @override
  String get defenseExplainCompleteKabeStillNotAbsolute =>
      'Four visible copies form a complete kabe and remove the relevant sequence route. Pair and special-hand waits can still remain.';

  @override
  String get defenseExplainIncompleteKabeLeavesSequencePossible =>
      'Three copies of the tile forming this incomplete kabe are publicly visible. The fourth may still be concealed, so the sequence route is not fully removed.';

  @override
  String get defenseExplainThreeVisibleHonorHasKokushiException =>
      'Three public copies plus your candidate account for all four copies. Ordinary pair waits are unavailable, but a Thirteen Orphans wait for that honor can still win by ron.';

  @override
  String get defenseExplainTwoVisibleHonorStillNotSafe =>
      'With two public copies and the candidate in your hand, another copy can still be concealed. Tanki or special-hand waits remain possible.';

  @override
  String get defenseExplainCombinedSujiAndKabeStillNotAbsolute =>
      'Suji and a complete kabe independently reduce ordinary sequence paths, but they do not prove safety against pair or special-hand waits.';

  @override
  String get defenseExplainTargetGenbutsuOutranksRelativeClues =>
      'The target\'s own discard is conclusive against that target\'s ron. Relative suji, kabe, and honor clues are not substitutes for genbutsu.';

  @override
  String get defenseExplainNoEstablishedSafetyEvidence =>
      'This lesson finds no genbutsu, suji, kabe, or visible-honor evidence that lowers this tile\'s risk against the target.';

  @override
  String get defenseNext => 'Next Question';

  @override
  String get defenseViewSummary => 'View Results';

  @override
  String get defenseSummaryTitle => 'Training Complete';

  @override
  String defenseSummaryScore(int correct, int total) {
    return '$correct of $total decisions matched the lesson.';
  }

  @override
  String defenseSummaryAccuracy(int accuracy) {
    return '$accuracy% accuracy';
  }

  @override
  String get defenseSummaryBreakdown => 'SKILL BREAKDOWN';

  @override
  String defenseSummaryTopicScore(int correct, int total) {
    return '$correct / $total';
  }

  @override
  String get defenseTryAgain => 'Try Again';

  @override
  String get defenseReviewDone => 'Finish Review';

  @override
  String get defenseDone => 'Back to Home';

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
  String get flashcardClose => 'Close';

  @override
  String get flashcardTapHint => 'Tap tile to see mnemonic';

  @override
  String get flashcardAccuracy => 'Accuracy';

  @override
  String get nanikiruNavTitle => 'Nani-Kiru · Tile Efficiency';

  @override
  String get nanikiruDiscardHint => 'Discard 1 tile for max efficiency';

  @override
  String get nanikiruEfficiencyScope =>
      'Pure tile efficiency: ignores dora, yaku, score, round state, and defense.';

  @override
  String get nanikiruGotIt => 'Got it';

  @override
  String get nanikiruAcceptanceGridTitle => 'Acceptance Tiles';

  @override
  String get collectionTitle => 'Yaku Collection';

  @override
  String get collectionClose => 'Close';

  @override
  String get collectionMastery => 'Mastery';

  @override
  String get tileBrowserTitle => 'Tile Browser';

  @override
  String get tileBrowserClose => 'Close';

  @override
  String get tileBrowserError => 'Error';

  @override
  String get commonGoBack => 'Go back';

  @override
  String get commonNotFound => 'Not found';

  @override
  String get settingsAppLanguage => 'App Language';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get profileTitle => 'Learning Profile';

  @override
  String get profileLocalProgress =>
      'Your learning progress is stored on this device.';

  @override
  String get profileElo => 'Skill rating';

  @override
  String get profileLearningStreak => 'Current streak';

  @override
  String get profileBestStreak => 'Best streak';

  @override
  String get profileLearningSection => 'Learning progress';

  @override
  String get profileTodayPlan => 'Today\'s plan';

  @override
  String profileTodayProgress(int current, int total) {
    return '$current/$total activities completed';
  }

  @override
  String get profileReviewQueue => 'Review queue';

  @override
  String profileReviewDue(int count) {
    return '$count due today';
  }

  @override
  String get profileAccountSection => 'Previous purchases';

  @override
  String get profilePreferencesSection => 'Preferences';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileSettingsDesc =>
      'Language, purchase restore, privacy, and terms';

  @override
  String get leaderboardKeepPlaying => 'Keep playing to climb the ranks!';

  @override
  String get leaderboardChangeName => 'Change name';

  @override
  String get consentTitle => 'Global Leaderboard';

  @override
  String get consentBody =>
      'Your scores will be uploaded to the global leaderboard. Your display name will be visible to other players. You can change your name anytime in the leaderboard.\n\nNo other personal data is collected. See our Privacy Policy for details.';

  @override
  String get consentAllow => 'Allow';

  @override
  String get consentNotNow => 'Not Now';

  @override
  String get flashcardSuitAll => '🎴 All';

  @override
  String get flashcardSuitMan => '🀇 Man';

  @override
  String get flashcardSuitPin => '🀙 Pin';

  @override
  String get flashcardSuitSou => '🀐 Sou';

  @override
  String get flashcardSuitHonor => '🀀 Honor';

  @override
  String get flashcardAllTiles => 'All Tiles';

  @override
  String flashcardSuiteFormat(Object suite) {
    return '$suite Flashcards';
  }

  @override
  String get flashcardStudyHint =>
      '📖 Study the mnemonic to remember this tile';

  @override
  String flashcardFinishedStats(Object correct, Object wrong) {
    return '✅ $correct correct · ❌ $wrong wrong';
  }

  @override
  String get nanikiruNew => 'NEW!';

  @override
  String get nanikiruDecision => '⏱ Decision: ';

  @override
  String get nanikiruHandLabel => 'YOUR HAND · 14 TILES';

  @override
  String get nanikiruSort => '📐 Sort';

  @override
  String get nanikiruHintTitle => '💡 Hint';

  @override
  String nanikiruSessionCount(Object count) {
    return '⚔$count';
  }

  @override
  String get leaderboardYou => 'YOU';

  @override
  String leaderboardStreak(Object count) {
    return '$count streak';
  }

  @override
  String leaderboardElo(Object elo) {
    return '$elo ELO';
  }

  @override
  String get settingsLearning => 'Learning';

  @override
  String get settingsDailyGoal => 'Daily Goal';

  @override
  String get settingsCountdown => 'Countdown';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignIn => 'Sign In';

  @override
  String get settingsComingSoon => 'Coming soon';

  @override
  String get settingsVersionLabel => 'Version';

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

  @override
  String get graveyardSrsReview => 'SRS Review';

  @override
  String get graveyardTodaysReview => 'TODAY\'S REVIEW';

  @override
  String graveyardReviewAll(int count) {
    return '⚡ Review All ($count)';
  }

  @override
  String get graveyardWeaknessRadar => 'Weakness Radar';

  @override
  String graveyardWeakest(Object suit, Object rate) {
    return '⚠ Weakest: $suit ($rate% error rate)';
  }

  @override
  String get graveyardNothingDue => 'Nothing due!\nAll caught up.';

  @override
  String graveyardErrorsOverdue(Object errors, Object days) {
    return '$errors errors · ${days}d overdue';
  }

  @override
  String graveyardDueCount(int count) {
    return '$count DUE';
  }

  @override
  String get yakuQuizTitle => 'Yaku Dojo';

  @override
  String get yakuQuizSubtitle => 'Test your knowledge of yaku and scoring.';

  @override
  String yakuQuizProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get yakuQuizCorrect => 'Correct!';

  @override
  String get yakuQuizIncorrect => 'Not quite';

  @override
  String get yakuQuizExplanation => 'Explanation';

  @override
  String get yakuQuizNext => 'Next Question';

  @override
  String get yakuQuizFinish => 'Finish';

  @override
  String get yakuQuizSummaryTitle => 'Training Complete';

  @override
  String yakuQuizSummaryBody(int correct, int total, int accuracy) {
    return 'You answered $correct of $total correctly.\nAccuracy: $accuracy%';
  }

  @override
  String get yakuQuizTryAgain => 'Try Again';

  @override
  String get yakuQuizTrue => 'True';

  @override
  String get yakuQuizFalse => 'False';

  @override
  String yakuQuizHanOption(int han) {
    return '$han Han';
  }

  @override
  String get yakuQuizStart => 'Start Training';

  @override
  String get yakuQuizTestMe => 'Test Me';

  @override
  String get yakuQuizReviewDone => 'Finish Review';

  @override
  String yakuDetailClosedHan(int han) {
    return '$han Han · closed only';
  }

  @override
  String yakuDetailClosedOpenHan(int closed, int open) {
    return '$closed Han closed · $open Han open';
  }

  @override
  String get yakuQuizPromptRiichiDefinition =>
      'Which yaku is declared in tenpai with a closed hand after placing a 1,000-point stick?';

  @override
  String get yakuQuizExplanationRiichiDefinition =>
      'Riichi is declared while in tenpai with a closed hand and is worth 1 han.';

  @override
  String get yakuQuizPromptTanyaoDefinition =>
      'Which yaku uses only numbered tiles 2–8, excluding terminals and honors?';

  @override
  String get yakuQuizExplanationTanyaoDefinition =>
      'Tanyao uses only numbered tiles 2–8, with no terminals or honors.';

  @override
  String get yakuQuizPromptPinfuDefinition =>
      'Which yaku requires a closed all-sequence hand, a non-value pair, and a two-sided wait?';

  @override
  String get yakuQuizExplanationPinfuDefinition =>
      'Pinfu is a closed hand of sequences with a non-value pair and a two-sided wait.';

  @override
  String get yakuQuizPromptYakuhaiDefinition =>
      'Which yaku is earned from a triplet or quad of dragons, the round wind, or the player\'s seat wind?';

  @override
  String get yakuQuizExplanationYakuhaiDefinition =>
      'A triplet or quad of dragons, the round wind, or the player\'s seat wind is worth 1 han.';

  @override
  String get yakuQuizPromptIipeikouDefinition =>
      'Which yaku uses two identical sequences in the same suit in a closed hand?';

  @override
  String get yakuQuizExplanationIipeikouDefinition =>
      'Iipeikou is two identical sequences in the same suit in a closed hand.';

  @override
  String get yakuQuizPromptChitoitsuDefinition =>
      'Which yaku is a closed hand made from seven distinct pairs?';

  @override
  String get yakuQuizExplanationChitoitsuDefinition =>
      'Chitoitsu is a closed hand of seven distinct pairs and is worth 2 han.';

  @override
  String get yakuQuizPromptToitoiDefinition =>
      'Which yaku consists of four triplets or quads and a pair?';

  @override
  String get yakuQuizExplanationToitoiDefinition =>
      'Toitoi consists of four triplets or quads and a pair; it is worth 2 han whether open or closed.';

  @override
  String get yakuQuizPromptSanshokuDefinition =>
      'Which yaku uses the same sequence in all three numbered suits?';

  @override
  String get yakuQuizExplanationSanshokuDefinition =>
      'Sanshoku Doujun uses the same sequence in all three suits and is worth 2 han closed or 1 han open.';

  @override
  String get yakuQuizPromptIkkitsukanDefinition =>
      'Which yaku combines 1-2-3, 4-5-6, and 7-8-9 in one suit?';

  @override
  String get yakuQuizExplanationIkkitsukanDefinition =>
      'Ikkitsukan combines 1-2-3, 4-5-6, and 7-8-9 in one suit; it is worth 2 han closed or 1 han open.';

  @override
  String get yakuQuizPromptHonitsuDefinition =>
      'Which yaku uses one numbered suit together with honor tiles?';

  @override
  String get yakuQuizExplanationHonitsuDefinition =>
      'Honitsu uses one numbered suit plus honors and is worth 3 han closed or 2 han open.';

  @override
  String get yakuQuizPromptChinitsuDefinition =>
      'Which yaku uses only one numbered suit and no honor tiles?';

  @override
  String get yakuQuizExplanationChinitsuDefinition =>
      'Chinitsu uses only one numbered suit with no honors and is worth 6 han closed or 5 han open.';

  @override
  String get yakuQuizPromptHonitsuOpenHan =>
      'What is Honitsu worth when the hand is open?';

  @override
  String get yakuQuizExplanationHonitsuOpenHan =>
      'An open Honitsu is worth 2 han; a closed Honitsu is worth 3 han.';

  @override
  String get yakuQuizPromptChinitsuOpenHan =>
      'What is Chinitsu worth when the hand is open?';

  @override
  String get yakuQuizExplanationChinitsuOpenHan =>
      'An open Chinitsu is worth 5 han; a closed Chinitsu is worth 6 han.';

  @override
  String get yakuQuizPromptSanshokuOpenHan =>
      'What is Sanshoku Doujun worth when the hand is open?';

  @override
  String get yakuQuizExplanationSanshokuOpenHan =>
      'An open Sanshoku Doujun is worth 1 han; a closed one is worth 2 han.';

  @override
  String get yakuQuizPromptJunchanClosedHan =>
      'What is Junchan worth with a closed hand?';

  @override
  String get yakuQuizExplanationJunchanClosedHan =>
      'A closed Junchan is worth 3 han; an open Junchan is worth 2 han.';

  @override
  String get yakuQuizPromptDoraIsYaku =>
      'Can dora alone satisfy the yaku requirement for winning?';

  @override
  String get yakuQuizExplanationDoraIsYaku =>
      'Dora add han but are not yaku. The hand still needs at least one valid yaku to win.';

  @override
  String get yakuQuizPromptPinfuClosedOnly =>
      'Can Pinfu be completed with an open hand?';

  @override
  String get yakuQuizExplanationPinfuClosedOnly =>
      'No. Pinfu is a closed-hand-only yaku.';

  @override
  String get yakuQuizPromptTanyaoAllowsHonors =>
      'Can a Tanyao hand contain honor tiles?';

  @override
  String get yakuQuizExplanationTanyaoAllowsHonors =>
      'No. Tanyao allows only numbered tiles 2–8, so honors and terminals are excluded.';
}
