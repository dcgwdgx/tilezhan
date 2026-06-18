// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'TileSlash';

  @override
  String get appTagline => 'Maîtrisez le Mahjong, une tuile à la fois';

  @override
  String get onboarding1Title => 'Maîtrisez la Reconnaissance\ndes Tuiles';

  @override
  String get onboarding1Desc =>
      'Quiz en 4 choix pour les 34 tuiles.\nCorrect = utilisez un cœur.\nErreur = révision gratuite à vie.';

  @override
  String get onboarding2Title => 'Entraînez votre\nEfficacité';

  @override
  String get onboarding2Desc =>
      'Tirez une tuile, puis choisissez\nla défausse optimale.\nLes réponses parfaites sont récompensées.';

  @override
  String get onboarding3Title => 'Commencez Gratuitement';

  @override
  String get onboarding3Desc =>
      'Aucune inscription requise.\n10 puzzles gratuits par jour.\nDébloquez l\'illimité avec Pro.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get homeDailyChallenge => 'DÉFI QUOTIDIEN';

  @override
  String get homeDailyDesc =>
      '3 puzzles. Sans coût d\'endurance. Réclamez votre récompense.';

  @override
  String get homeStartChallenge => '⚡ COMMENCER LE DÉFI';

  @override
  String get homeQuickAccess => 'ACCÈS RAPIDE';

  @override
  String get homeFlashcards => 'Cartes Mémoire';

  @override
  String get homeNanikiru => 'Nani-Kiru';

  @override
  String get homeScanner => 'Scanner';

  @override
  String get homeCollection => 'Guide Yaku';

  @override
  String get homeGraveyard => 'Cimetière';

  @override
  String get homeTileBrowser => 'Tuiles';

  @override
  String get homeProfile => 'Profil';

  @override
  String get homePremium => 'Premium';

  @override
  String get homeSettings => 'Paramètres';

  @override
  String get homeRank => 'Classement';

  @override
  String get homeUpgrade => 'UPGRADE';

  @override
  String get homePro => 'PRO';

  @override
  String homeFreeCount(int count) {
    return '$count/3 gratuits';
  }

  @override
  String get battleTitle => 'Rapport du Jour';

  @override
  String get battleTotal => 'Total';

  @override
  String get battleAccuracy => 'Précision';

  @override
  String get battleMaxCombo => 'Combo Max';

  @override
  String get battleMistakeHint =>
      'Révisez les erreurs à tout moment — gratuit, sans limites';

  @override
  String get battlePremiumCTA => '4,99 \$/mois — Jeu Illimité';

  @override
  String get battleMistakes => 'Réviser les Erreurs';

  @override
  String get battleShare => 'Partager';

  @override
  String get battleInvite => 'Inviter';

  @override
  String get battleMistakesBtn => 'Erreurs';

  @override
  String get battleComboBanner => 'COMBO ×10 !';

  @override
  String get battleComboSub => 'Annuel -20% — 23,99 \$/an';

  @override
  String get battleComboUnlock => 'DÉBLOQUER';

  @override
  String get battleDomain => 'tilezhan.app';

  @override
  String get premiumTitle => 'Choisissez Votre Formule';

  @override
  String get premiumConnecting => 'Connexion à l\'App Store...';

  @override
  String get premiumContinue => 'CONTINUER';

  @override
  String get premiumSelectPlan => 'SÉLECTIONNEZ UNE FORMULE';

  @override
  String get premiumPurchasing => 'ACHAT EN COURS...';

  @override
  String get premiumRestore => 'Restaurer les Achats';

  @override
  String get premiumAllPlansHeader => 'Toutes les formules payantes incluent :';

  @override
  String get premiumAllPlansFooter =>
      '✅ Puzzles illimités   ✅ Mode Fantôme (révision)   ✅ Annulez à tout moment';

  @override
  String get premiumFree => 'GRATUIT';

  @override
  String get premiumMonthly => 'MENSUEL';

  @override
  String get premiumAnnual => 'ANNUEL';

  @override
  String get premiumLifetime => 'VIE';

  @override
  String get premiumPopular => '★ POPULAIRE';

  @override
  String get premiumBestValue => 'MEILLEUR PRIX — -50%';

  @override
  String get premiumPayOnce => 'PAIEMENT UNIQUE';

  @override
  String get premiumLaunchBanner =>
      'Offre de lancement : Vie -20% — Offre limitée';

  @override
  String shareStats(Object total, Object accuracy, Object combo) {
    return '🎯 $total puzzles aujourd\'hui · $accuracy% de précision · $combo× combo max sur TileZhan ! tilezhan.app';
  }

  @override
  String get inviteText =>
      '🀄 Rejoignez-moi sur TileZhan — maîtrisez le Mahjong ! Puzzles gratuits quotidiens. tilezhan.app';

  @override
  String get comboTitle => 'COMBO ×10 !';

  @override
  String get comboSubtitle =>
      'Vous êtes en feu ! Débloquez le jeu illimité\net gardez votre série.';

  @override
  String get comboOffer => 'OFFRE SPÉCIALE';

  @override
  String get comboDiscount => '-20%';

  @override
  String get comboUnlock => 'DÉBLOQUER — 23,99 \$';

  @override
  String get comboMaybe => 'Plus tard';

  @override
  String get nanikiruDraw => 'Vous venez de piocher :';

  @override
  String nanikiruCorrect(Object discard) {
    return 'Défausse correcte : $discard';
  }

  @override
  String nanikiruYourDiscard(Object discard) {
    return 'Votre défausse : $discard';
  }

  @override
  String nanikiruBestDiscard(Object discard, Object count, Object types) {
    return 'Meilleure défausse : $discard  →  $count types, $types tuiles d\'acceptation';
  }

  @override
  String get nanikiruPerfectExplain =>
      'Maximiser l\'acceptation des tuiles — cette défausse vous donne le plus de possibilités de compléter votre main.';

  @override
  String get nanikiruHint =>
      'Cherchez des séquences et des brelans.\nDéfaussez les tuiles isolées.\nLa bonne réponse maximise l\'acceptation (ukeire).';

  @override
  String get nanikiruSkip => '🏳️ Passer';

  @override
  String get nanikiruConfirm => 'Confirmer';

  @override
  String get nanikiruTapToContinue => 'Touchez n\'importe où pour continuer';

  @override
  String get nanikiruPerfect => '🎯 PARFAIT !';

  @override
  String get nanikiruBlunder => '💥 ERREUR !';

  @override
  String get nanikiruAcceptanceTiles => 'Tuiles d\'Acceptation';

  @override
  String get nanikiruNextPuzzle => 'Puzzle suivant';

  @override
  String get nanikiruReviewAgain => 'Revoir';

  @override
  String get nanikiruAcceptanceComparison => 'Comparaison d\'acceptation';

  @override
  String get nanikiruYourDiscardLabel => 'Votre défausse';

  @override
  String get nanikiruBestDiscardLabel => 'Meilleure défausse';

  @override
  String get scannerTitle => 'Scanner Yaku';

  @override
  String get scannerDesc =>
      'Scan complet à venir en V2.\nParcourez les 10 yaku de base ci-dessous.';

  @override
  String get scannerBasicYaku => 'YAKU DE BASE';

  @override
  String get scannerFavorites => 'FAVORIS';

  @override
  String get leaderboardTitle => 'Classement';

  @override
  String get leaderboardEmpty => 'Soyez le premier au classement !';

  @override
  String get leaderboardEmptySub =>
      'Complétez des puzzles pour gagner votre place.';

  @override
  String get leaderboardRetry => 'Réessayer';

  @override
  String get leaderboardMyRank => 'Mon classement';

  @override
  String get leaderboardNotRanked => 'Jouez pour gagner votre place !';

  @override
  String get leaderboardEnterName => 'Entrez votre nom';

  @override
  String get leaderboardNameHint => 'Votre nom d\'affichage';

  @override
  String get leaderboardSaveName => 'Enregistrer';

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
  String get flashcardPlayAgain => '🔄 Rejouer';

  @override
  String get flashcardGotIt => 'Compris ✓';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAnimation => 'Animation Speed';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsVersion => 'Version 1.0.0';

  @override
  String get rankNovice => 'Novice';

  @override
  String get rankApprentice => 'Apprenti';

  @override
  String get rankAdept => 'Adepte';

  @override
  String get rankExpert => 'Expert';

  @override
  String get rankMaster => 'Maître';

  @override
  String rankReviews(Object count) {
    return '$count révisions';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navTiles => 'Tuiles';

  @override
  String get navYaku => 'Yaku';

  @override
  String get navReview => 'Réviser';
}
