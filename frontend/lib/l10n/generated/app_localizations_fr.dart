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
      'Quiz en 4 choix pour les 34 tuiles.\nLes bonnes réponses sont toujours gratuites.\nLes erreurs rejoignent vos révisions.';

  @override
  String get onboarding2Title => 'Entraînez votre\nEfficacité';

  @override
  String get onboarding2Desc =>
      'Tirez une tuile, puis choisissez\nla défausse optimale.\nLes réponses parfaites sont récompensées.';

  @override
  String get onboarding3Title => 'Créez une Routine\nd\'Apprentissage';

  @override
  String get onboarding3Desc =>
      'Suivez un programme court adapté à vos révisions et à vos exercices récents.\nAucune inscription requise. Tous les entraînements sont gratuits dans cette version.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer la Première Leçon';

  @override
  String get homeDailyChallenge => 'DÉFI QUOTIDIEN';

  @override
  String get homeDailyDesc =>
      'Terminez 3 exercices d\'efficacité sans endurance et entretenez votre série quotidienne.';

  @override
  String get homeStartChallenge => '⚡ COMMENCER LE DÉFI';

  @override
  String get homeQuickAccess => 'ACCÈS RAPIDE';

  @override
  String get homeFlashcards => 'Cartes Mémoire';

  @override
  String get homeNanikiru => 'Nani-Kiru';

  @override
  String get homeDefenseTraining => 'Entraînement défensif';

  @override
  String get homeScanner => 'Référence yaku';

  @override
  String get homeHandAnalyzer => 'Analyse de main';

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
  String homeHeartsRemaining(int count) {
    return '$count cœurs restants';
  }

  @override
  String dailyStreak(int count) {
    return '🔥 Série de $count jours';
  }

  @override
  String dailyProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get dailyViewResult => 'VOIR LE RÉSULTAT DU JOUR';

  @override
  String get dailySummaryTitle => 'Défi quotidien terminé';

  @override
  String dailySummaryBody(int correct, int total, int accuracy, int streak) {
    return 'Vous avez réussi $correct/$total exercices.\nPrécision : $accuracy%\nSérie d\'apprentissage : $streak jours';
  }

  @override
  String get trainingLoading => 'Préparation du programme du jour...';

  @override
  String get trainingLoadError =>
      'Impossible de charger le programme du jour. Vous pouvez réessayer sans perdre votre progression enregistrée.';

  @override
  String get trainingRetry => 'RÉESSAYER';

  @override
  String get trainingSaveError =>
      'Impossible d’enregistrer votre progression. Vérifiez le stockage de l’appareil, puis réessayez.';

  @override
  String get trainingSaveRetry => 'RÉESSAYER L’ENREGISTREMENT';

  @override
  String get trainingTodayTitle => 'Programme du jour · 5 min';

  @override
  String get trainingTodaySubtitle =>
      'Un parcours ciblé selon vos révisions et vos exercices récents.';

  @override
  String trainingPlanProgress(int current, int total) {
    return '$current/$total terminés';
  }

  @override
  String get trainingStreakStart => 'Commencez votre série d\'apprentissage';

  @override
  String trainingLearningStreak(int count) {
    return '🔥 Série d\'apprentissage de $count jours';
  }

  @override
  String get trainingPlanComplete => 'PROGRAMME TERMINÉ';

  @override
  String get trainingStartPlan => 'COMMENCER LE PROGRAMME';

  @override
  String get trainingContinuePlan => 'CONTINUER LE PROGRAMME';

  @override
  String get trainingTaskStarterTiles => 'Apprendre les tuiles essentielles';

  @override
  String get trainingTaskDueReview => 'Terminer les révisions du jour';

  @override
  String trainingTaskWeakSkill(String skill) {
    return 'Renforcer : $skill';
  }

  @override
  String get trainingTaskDailyEfficiency => 'Défi quotidien d\'efficacité';

  @override
  String get trainingTaskExploreDefense => 'Découvrir la lecture défensive';

  @override
  String get trainingTaskExploreYaku => 'Découvrir les yakus';

  @override
  String get trainingTaskStarterDesc =>
      'Reconnaissez instantanément les tuiles avec trois cartes rapides.';

  @override
  String trainingTaskDueDesc(int count) {
    return 'Révisez $count élément(s) prévus aujourd\'hui.';
  }

  @override
  String get trainingTaskDailyDesc =>
      'Prenez trois décisions de défausse et comparez leur efficacité.';

  @override
  String get trainingTaskExploreDefenseDesc =>
      'Apprenez à classer les défausses sûres grâce aux indices visibles.';

  @override
  String get trainingTaskExploreYakuDesc =>
      'Vérifiez les définitions et les règles qui valident une main gagnante.';

  @override
  String get trainingTaskWeakDesc =>
      'Entraînez-vous avec des questions ciblées sur cette faiblesse.';

  @override
  String trainingTaskWeakEvidence(int correct, int attempts) {
    return 'Résultats récents : $correct/$attempts corrects';
  }

  @override
  String get trainingSkillIsolatedTiles => 'choix de tuiles isolées';

  @override
  String get trainingSkillTaatsuOverload => 'formes surchargées';

  @override
  String get trainingSkillPairProtection => 'protection des paires';

  @override
  String get trainingSkillChiitoitsuChoice => 'décisions de sept paires';

  @override
  String get trainingSkillKokushiShape => 'formes des treize orphelins';

  @override
  String get trainingSkillTileEfficiency => 'efficacité des tuiles';

  @override
  String get trainingSkillGeneral => 'faiblesses récentes';

  @override
  String get dailySummaryDone => 'Terminé';

  @override
  String get reviewFinish => 'Terminer la révision';

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
  String get battlePremiumCTA => 'Voir les offres Premium';

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
  String get battleComboSub =>
      'Consultez les offres actuellement disponibles dans la boutique';

  @override
  String get battleComboUnlock => 'VOIR LES OFFRES';

  @override
  String get battleDomain => 'tilezhan.app';

  @override
  String get premiumTitle => 'Choisissez Votre Formule';

  @override
  String get premiumConnecting => 'Connexion à la boutique...';

  @override
  String get premiumContinue => 'CONTINUER';

  @override
  String get premiumSelectPlan => 'SÉLECTIONNEZ UNE FORMULE';

  @override
  String get premiumPurchasing => 'ACHAT EN COURS...';

  @override
  String get premiumRestore => 'Restaurer les Achats';

  @override
  String get premiumFreeReleaseTitle =>
      'Tous les entraînements sont gratuits dans cette version';

  @override
  String get premiumFreeReleaseBody =>
      'Entraînez-vous sans limite d\'endurance ni de difficulté. Vos résultats et la révision de vos erreurs restent disponibles.';

  @override
  String get premiumRestoreHint =>
      'Vous aviez effectué un achat dans une version précédente ? Restaurez ici votre historique d\'achats.';

  @override
  String get premiumRestoring => 'RESTAURATION...';

  @override
  String get premiumRestoreRequested =>
      'Demande de restauration envoyée. Votre accès sera mis à jour après confirmation de la boutique.';

  @override
  String get premiumRestoreFailed =>
      'Impossible de restaurer les achats. Veuillez réessayer.';

  @override
  String get premiumNoProducts =>
      'Les achats sont temporairement indisponibles. Aucun produit n\'est actuellement proposé dans la boutique.';

  @override
  String get premiumUnavailable =>
      'La boutique est temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get premiumRetry => 'RÉESSAYER';

  @override
  String get premiumPurchaseStarted =>
      'Demande d\'achat envoyée. Suivez les instructions de la boutique pour terminer.';

  @override
  String get premiumPurchaseFailed =>
      'Impossible de démarrer l\'achat. Veuillez réessayer.';

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
  String get premiumPrivacy => 'Politique de confidentialité';

  @override
  String get premiumTerms => 'Conditions d\'utilisation';

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
    return 'Meilleure défausse : $discard  →  $types types, $count tuiles d\'acceptation';
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
  String get nanikiruSkippedTitle => 'PASSÉ';

  @override
  String get nanikiruTimedOutTitle => 'TEMPS ÉCOULÉ !';

  @override
  String get nanikiruTopCandidatesTitle => 'Meilleurs choix de défausse';

  @override
  String get nanikiruBestBadge => 'MEILLEUR';

  @override
  String get nanikiruSelectedBadge => 'VOTRE CHOIX';

  @override
  String get nanikiruTenpai => 'Tenpai';

  @override
  String nanikiruShantenValue(int shanten) {
    return 'Shanten : $shanten';
  }

  @override
  String nanikiruAcceptanceSummary(int types, int count) {
    return 'Types : $types · Tuiles : $count';
  }

  @override
  String nanikiruUkeireLoss(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tuiles d\'acceptation de moins que la meilleure défausse',
      one: '1 tuile d\'acceptation de moins que la meilleure défausse',
    );
    return '$_temp0';
  }

  @override
  String nanikiruShantenLoss(int shanten) {
    return 'Recule de $shanten shanten';
  }

  @override
  String get nanikiruNoSelection => 'Aucune tuile sélectionnée';

  @override
  String nanikiruTimeoutChoice(String discard) {
    return 'Choix à l\'expiration du temps : $discard';
  }

  @override
  String get nanikiruSkillsTitle => 'Compétences travaillées';

  @override
  String get nanikiruTypesLabel => 'Types';

  @override
  String get nanikiruSkillIsolatedTile => 'Gestion des tuiles isolées';

  @override
  String get nanikiruSkillTaatsuOverload => 'Sélection des taatsu';

  @override
  String get nanikiruSkillPairProtection => 'Préservation des paires';

  @override
  String get nanikiruSkillChiitoitsu => 'Voie des sept paires';

  @override
  String get nanikiruSkillKokushi => 'Voie des treize orphelins';

  @override
  String get nanikiruSkillGeneralEfficiency => 'Efficacité des tuiles';

  @override
  String get nanikiruNotOptimalTitle => 'PAS OPTIMAL';

  @override
  String get nanikiruDecisionLossTitle => 'Impact du choix';

  @override
  String get nanikiruNoDecisionLoss =>
      'Meilleur choix — aucune perte d\'efficacité';

  @override
  String nanikiruRankLabel(int rank) {
    return 'Rang n° $rank';
  }

  @override
  String nanikiruDiscardLabel(String tile) {
    return 'Défausse : $tile';
  }

  @override
  String get scannerTitle => 'Référence yaku';

  @override
  String get scannerDesc =>
      'Consultez les yaku ci-dessous ou ouvrez le dōjō pour tester vos connaissances.';

  @override
  String get scannerBasicYaku => 'YAKU DE BASE';

  @override
  String get scannerFavorites => 'FAVORIS';

  @override
  String get scannerBeginner => 'Débutant';

  @override
  String get scannerIntermediate => 'Intermédiaire';

  @override
  String get scannerAdvanced => 'Avancé';

  @override
  String get scannerYakuman => 'Yakuman';

  @override
  String scannerYakuCount(int count) {
    return '$count yaku';
  }

  @override
  String get handAnalyzerTitle => 'Analyse de main';

  @override
  String get handAnalyzerSubtitle =>
      'Saisissez une main fermée de 13 ou 14 tuiles pour une analyse exacte de l’efficacité.';

  @override
  String get handAnalyzerScope =>
      'Efficacité pure uniquement. Les dora, yaku, points, tuiles visibles, appels et la défense ne sont pas pris en compte.';

  @override
  String get handAnalyzerHand => 'VOTRE MAIN';

  @override
  String handAnalyzerTileCount(int count, int target) {
    return '$count / $target tuiles';
  }

  @override
  String get handAnalyzerNeedTileCount =>
      'Saisissez exactement 13 ou 14 tuiles pour lancer l’analyse.';

  @override
  String get handAnalyzerFourCopyLimit =>
      'Une même tuile ne peut apparaître que quatre fois.';

  @override
  String get handAnalyzerRemoveHint =>
      'Touchez une tuile de votre main pour la retirer.';

  @override
  String get handAnalyzerPicker => 'AJOUTER DES TUILES';

  @override
  String get handAnalyzerMan => 'Manzu';

  @override
  String get handAnalyzerPin => 'Pinzu';

  @override
  String get handAnalyzerSou => 'Souzu';

  @override
  String get handAnalyzerHonors => 'Honneurs';

  @override
  String get handAnalyzerAnalyze => 'Analyser la main';

  @override
  String get handAnalyzerClear => 'Effacer';

  @override
  String get handAnalyzerCurrentShanten => 'Shanten actuel';

  @override
  String get handAnalyzerComplete => 'Main complète';

  @override
  String get handAnalyzerTenpai => 'Tenpai';

  @override
  String handAnalyzerShantenValue(int count) {
    return 'Shanten $count';
  }

  @override
  String get handAnalyzerImprovingTiles => 'Tuiles améliorantes';

  @override
  String handAnalyzerEffectiveSummary(int types, int count) {
    return '$types types · $count tuiles';
  }

  @override
  String get handAnalyzerDiscardCandidates => 'Tuiles à défausser';

  @override
  String handAnalyzerCandidateSummary(String shanten, int types, int count) {
    return 'Après défausse : $shanten · $types types · $count tuiles';
  }

  @override
  String get handAnalyzerBest => 'MEILLEUR';

  @override
  String handAnalyzerRank(int rank) {
    return 'Nº $rank';
  }

  @override
  String get handAnalyzerNoImprovingTiles =>
      'Aucune tuile améliorante dans cet état.';

  @override
  String get handAnalyzerSave => 'Enregistrer l’analyse';

  @override
  String get handAnalyzerSaved => 'Analyse ajoutée aux mains récentes.';

  @override
  String get handAnalyzerRecent => 'ANALYSES RÉCENTES';

  @override
  String get handAnalyzerRecentEmpty =>
      'Les mains enregistrées apparaîtront ici.';

  @override
  String get handAnalyzerOpen => 'Ouvrir';

  @override
  String get handAnalyzerDelete => 'Supprimer';

  @override
  String get handAnalyzerShapeBreakdown => 'Détail des formes';

  @override
  String get handAnalyzerStandard => 'Main standard';

  @override
  String get handAnalyzerSevenPairs => 'Sept paires';

  @override
  String get handAnalyzerThirteenOrphans => 'Treize orphelins';

  @override
  String get handAnalyzerError =>
      'Impossible d’analyser cette main. Vérifiez le nombre de tuiles et réessayez.';

  @override
  String get defenseTitle => 'Entraînement défensif';

  @override
  String get defenseIntroTitle => 'Évaluez le danger avant de défausser';

  @override
  String get defenseIntroBody =>
      'Entraînez-vous à choisir la tuile la moins risquée face à un adversaire en riichi grâce aux indices visibles.';

  @override
  String get defenseScope =>
      'Un genbutsu n’est sûr que face au joueur ciblé. Le suji, le kabe et les honneurs visibles peuvent réduire certains risques sans jamais garantir la sécurité.';

  @override
  String defenseSessionLength(int count) {
    return 'Session de $count questions';
  }

  @override
  String get defenseStart => 'Commencer l’entraînement';

  @override
  String defenseProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get defenseQuestionPrompt =>
      'Quelle défausse présente le moins de risque face au joueur ciblé dans cette situation ?';

  @override
  String defenseTargetRiver(String seat) {
    return 'Rivière de la cible en riichi · $seat';
  }

  @override
  String defenseOtherRiver(String seat) {
    return 'Autre rivière · $seat';
  }

  @override
  String get defenseAdditionalVisible => 'AUTRES TUILES VISIBLES';

  @override
  String defenseVisibleCopies(int count) {
    return '$count visibles';
  }

  @override
  String defenseVisibleTileSemantics(String tile, int count) {
    return '$tile, $count exemplaires visibles';
  }

  @override
  String defenseTileSemantics(String tile) {
    return 'Tuile $tile';
  }

  @override
  String defenseNumberedTile(int number, String suit) {
    return '$number de $suit';
  }

  @override
  String get defenseTileManSuit => 'caractères';

  @override
  String get defenseTilePinSuit => 'cercles';

  @override
  String get defenseTileSouSuit => 'bambous';

  @override
  String get defenseTileEastWind => 'Vent d’Est';

  @override
  String get defenseTileSouthWind => 'Vent du Sud';

  @override
  String get defenseTileWestWind => 'Vent d’Ouest';

  @override
  String get defenseTileNorthWind => 'Vent du Nord';

  @override
  String get defenseTileRedDragon => 'Dragon rouge';

  @override
  String get defenseTileGreenDragon => 'Dragon vert';

  @override
  String get defenseTileWhiteDragon => 'Dragon blanc';

  @override
  String get defenseChoicesTitle => 'CHOISISSEZ UNE DÉFAUSSE';

  @override
  String defenseChooseTile(String tile) {
    return 'Choisir $tile';
  }

  @override
  String get defenseLoadError => 'Impossible de charger la leçon de défense.';

  @override
  String get defenseRetry => 'Réessayer';

  @override
  String get defenseTopicGenbutsu => 'Genbutsu';

  @override
  String get defenseTopicSuji => 'Suji';

  @override
  String get defenseTopicKabe => 'Kabe';

  @override
  String get defenseTopicHonorVisibility => 'Honneurs visibles';

  @override
  String get defenseTopicCombinedEvidence => 'Indices combinés';

  @override
  String get defenseSeatEast => 'Est';

  @override
  String get defenseSeatSouth => 'Sud';

  @override
  String get defenseSeatWest => 'Ouest';

  @override
  String get defenseSeatNorth => 'Nord';

  @override
  String get defenseGoodDecision => 'Bonne décision';

  @override
  String get defenseReviewChoice => 'Revoyez ce choix';

  @override
  String get defenseYourChoice => 'Votre choix';

  @override
  String get defenseRecommendedChoice => 'Choix recommandé';

  @override
  String get defenseSelected => 'CHOISI';

  @override
  String get defenseRecommended => 'RECOMMANDÉ';

  @override
  String get defenseEvidenceTitle => 'Indices défensifs';

  @override
  String get defenseRiskAbsoluteAgainstTarget =>
      'Sûr face à la cible · genbutsu';

  @override
  String get defenseRiskStronglyReducedNotAbsolute =>
      'Risque fortement réduit · sécurité non garantie';

  @override
  String get defenseRiskRelativelyReducedNotAbsolute =>
      'Indice de risque réduit · sécurité non garantie';

  @override
  String get defenseRiskNoEstablishedReduction =>
      'Aucune réduction de risque établie';

  @override
  String get defenseExplainTargetOwnDiscardIsGenbutsu =>
      'Cette tuile figure dans la propre rivière du joueur ciblé. Le furiten empêche ce joueur de gagner par ron sur cette même tuile ; cela ne dit rien sur les autres joueurs.';

  @override
  String get defenseExplainOtherOpponentDiscardIsNotTargetGenbutsu =>
      'Cette tuile figure uniquement dans la rivière d’un autre joueur ; elle n’est donc pas genbutsu face à la cible.';

  @override
  String get defenseExplainSujiCoversOnlyRyanmen =>
      'La rivière de la cible fournit un indice suji qui élimine certaines attentes bilatérales. Les attentes tanki, shanpon, de bord, fermées et de mains spéciales restent possibles.';

  @override
  String get defenseExplainCompleteKabeStillNotAbsolute =>
      'Quatre exemplaires visibles forment un kabe complet et éliminent la voie de suite concernée. Les attentes de paire et de mains spéciales restent possibles.';

  @override
  String get defenseExplainIncompleteKabeLeavesSequencePossible =>
      'Trois exemplaires de la tuile qui forme ce kabe incomplet sont visibles publiquement. Le quatrième peut encore être caché ; la voie de suite n’est donc pas entièrement éliminée.';

  @override
  String get defenseExplainThreeVisibleHonorHasKokushiException =>
      'Les trois exemplaires publics et votre tuile candidate représentent les quatre exemplaires. Une attente de paire ordinaire est impossible, mais une attente des Treize Orphelins sur cet honneur peut encore gagner par ron.';

  @override
  String get defenseExplainTwoVisibleHonorStillNotSafe =>
      'Avec deux exemplaires publics et la tuile candidate dans votre main, un autre exemplaire peut encore être caché. Une attente tanki ou de main spéciale reste possible.';

  @override
  String get defenseExplainCombinedSujiAndKabeStillNotAbsolute =>
      'Le suji et un kabe complet réduisent indépendamment les voies de suites ordinaires, sans prouver la sécurité face aux attentes de paire ou de mains spéciales.';

  @override
  String get defenseExplainTargetGenbutsuOutranksRelativeClues =>
      'La propre défausse de la cible exclut son ron sur cette tuile. Les indices relatifs de suji, de kabe ou d’honneurs ne remplacent pas un genbutsu.';

  @override
  String get defenseExplainNoEstablishedSafetyEvidence =>
      'Cette leçon ne trouve aucun indice de genbutsu, de suji, de kabe ou d’honneur visible réduisant le risque de cette tuile face à la cible.';

  @override
  String get defenseNext => 'Question suivante';

  @override
  String get defenseViewSummary => 'Voir les résultats';

  @override
  String get defenseSummaryTitle => 'Entraînement terminé';

  @override
  String defenseSummaryScore(int correct, int total) {
    return '$correct décisions sur $total correspondent à la leçon.';
  }

  @override
  String defenseSummaryAccuracy(int accuracy) {
    return '$accuracy % de réussite';
  }

  @override
  String get defenseSummaryBreakdown => 'RÉSULTATS PAR COMPÉTENCE';

  @override
  String defenseSummaryTopicScore(int correct, int total) {
    return '$correct / $total';
  }

  @override
  String get defenseTryAgain => 'Recommencer';

  @override
  String get defenseReviewDone => 'Terminer la révision';

  @override
  String get defenseDone => 'Retour à l’accueil';

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
  String get flashcardPerfect => 'Parfait !';

  @override
  String get flashcardCorrect => 'Correct';

  @override
  String get flashcardIncorrect => 'Incorrect';

  @override
  String get flashcardTimeout => 'Temps écoulé';

  @override
  String get flashcardPlayAgain => '🔄 Rejouer';

  @override
  String get flashcardGotIt => 'Compris ✓';

  @override
  String get flashcardClose => 'Fermer';

  @override
  String get flashcardTapHint => 'Touchez la tuile pour voir l\'aide';

  @override
  String get flashcardAccuracy => 'Précision';

  @override
  String get nanikiruNavTitle => 'Nani-Kiru · Efficacité';

  @override
  String get nanikiruDiscardHint => 'Défaussez 1 tuile pour une efficacité max';

  @override
  String get nanikiruEfficiencyScope =>
      'Efficacité pure : sans dora, yaku, score, situation de manche ni défense.';

  @override
  String get nanikiruGotIt => 'Compris';

  @override
  String get nanikiruAcceptanceGridTitle => 'Tuiles d\'acceptation';

  @override
  String get collectionTitle => 'Collection Yaku';

  @override
  String get collectionClose => 'Fermer';

  @override
  String get collectionMastery => 'Maîtrise';

  @override
  String get tileBrowserTitle => 'Tuiles';

  @override
  String get tileBrowserClose => 'Fermer';

  @override
  String get tileBrowserError => 'Erreur';

  @override
  String get commonGoBack => 'Retour';

  @override
  String get commonNotFound => 'Non trouvé';

  @override
  String get settingsAppLanguage => 'Langue';

  @override
  String get settingsLanguageSection => 'Langue';

  @override
  String get profileTitle => 'Profil d\'apprentissage';

  @override
  String get profileLocalProgress =>
      'Votre progression est enregistrée sur cet appareil.';

  @override
  String get profileElo => 'Niveau estimé';

  @override
  String get profileLearningStreak => 'Série actuelle';

  @override
  String get profileBestStreak => 'Meilleure série';

  @override
  String get profileLearningSection => 'Progression';

  @override
  String get profileTodayPlan => 'Programme du jour';

  @override
  String profileTodayProgress(int current, int total) {
    return '$current/$total activités terminées';
  }

  @override
  String get profileReviewQueue => 'File de révision';

  @override
  String profileReviewDue(int count) {
    return '$count à réviser aujourd\'hui';
  }

  @override
  String get profileAccountSection => 'Achats précédents';

  @override
  String get profilePreferencesSection => 'Préférences';

  @override
  String get profileSettings => 'Paramètres';

  @override
  String get profileSettingsDesc =>
      'Langue, restauration des achats, confidentialité et conditions';

  @override
  String get leaderboardKeepPlaying => 'Continuez à jouer pour grimper !';

  @override
  String get leaderboardChangeName => 'Changer de nom';

  @override
  String get consentTitle => 'Classement mondial';

  @override
  String get consentBody =>
      'Vos scores seront téléchargés vers le classement mondial. Votre nom sera visible par les autres joueurs. Vous pouvez changer de nom à tout moment.\n\nAucune autre donnée personnelle n\'est collectée. Voir notre politique de confidentialité.';

  @override
  String get consentAllow => 'Autoriser';

  @override
  String get consentNotNow => 'Pas maintenant';

  @override
  String get flashcardSuitAll => '🎴 Tout';

  @override
  String get flashcardSuitMan => '🀇 Man';

  @override
  String get flashcardSuitPin => '🀙 Pin';

  @override
  String get flashcardSuitSou => '🀐 Sou';

  @override
  String get flashcardSuitHonor => '🀀 Honneur';

  @override
  String get flashcardAllTiles => 'Toutes les tuiles';

  @override
  String flashcardSuiteFormat(Object suite) {
    return '$suite Flashcards';
  }

  @override
  String get flashcardStudyHint =>
      '📖 Étudiez l\'aide pour mémoriser cette tuile';

  @override
  String flashcardFinishedStats(Object correct, Object wrong) {
    return '✅ $correct correct · ❌ $wrong faux';
  }

  @override
  String get nanikiruNew => 'NOUVEAU!';

  @override
  String get nanikiruDecision => '⏱ Décision : ';

  @override
  String get nanikiruHandLabel => 'VOTRE MAIN · 14 TUILES';

  @override
  String get nanikiruSort => '📐 Trier';

  @override
  String get nanikiruHintTitle => '💡 Conseil';

  @override
  String nanikiruSessionCount(Object count) {
    return '⚔$count';
  }

  @override
  String get leaderboardYou => 'VOUS';

  @override
  String leaderboardStreak(Object count) {
    return '$count série';
  }

  @override
  String leaderboardElo(Object elo) {
    return '$elo ELO';
  }

  @override
  String get settingsLearning => 'Apprentissage';

  @override
  String get settingsDailyGoal => 'Objectif quotidien';

  @override
  String get settingsCountdown => 'Compte à rebours';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsSignIn => 'Connexion';

  @override
  String get settingsComingSoon => 'Bientôt disponible';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAnimation => 'Vitesse des animations';

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

  @override
  String get graveyardSrsReview => 'Révision SRS';

  @override
  String get graveyardTodaysReview => 'RÉVISION DU JOUR';

  @override
  String graveyardReviewAll(int count) {
    return '⚡ Tout réviser ($count)';
  }

  @override
  String get graveyardWeaknessRadar => 'Radar de faiblesses';

  @override
  String graveyardWeakest(Object suit, Object rate) {
    return '⚠ Plus faible : $suit ($rate% d\'erreurs)';
  }

  @override
  String get graveyardNothingDue => 'Rien à réviser !\nTout est à jour.';

  @override
  String graveyardErrorsOverdue(Object errors, Object days) {
    return '$errors erreurs · ${days}j de retard';
  }

  @override
  String graveyardDueCount(int count) {
    return '$count À FAIRE';
  }

  @override
  String get yakuQuizTitle => 'Dōjō des yaku';

  @override
  String get yakuQuizSubtitle =>
      'Testez vos connaissances sur les yaku et leur valeur en han.';

  @override
  String yakuQuizProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get yakuQuizCorrect => 'Bonne réponse !';

  @override
  String get yakuQuizIncorrect => 'Pas tout à fait';

  @override
  String get yakuQuizExplanation => 'Explication';

  @override
  String get yakuQuizNext => 'Question suivante';

  @override
  String get yakuQuizFinish => 'Terminer';

  @override
  String get yakuQuizSummaryTitle => 'Entraînement terminé';

  @override
  String yakuQuizSummaryBody(int correct, int total, int accuracy) {
    return 'Vous avez donné $correct bonnes réponses sur $total.\nPrécision : $accuracy %';
  }

  @override
  String get yakuQuizTryAgain => 'Réessayer';

  @override
  String get yakuQuizTrue => 'Vrai';

  @override
  String get yakuQuizFalse => 'Faux';

  @override
  String yakuQuizHanOption(int han) {
    return '$han han';
  }

  @override
  String get yakuQuizStart => 'Commencer l\'entraînement';

  @override
  String get yakuQuizTestMe => 'Tester mes connaissances';

  @override
  String get yakuQuizReviewDone => 'Terminer la révision';

  @override
  String yakuDetailClosedHan(int han) {
    return '$han han · main fermée uniquement';
  }

  @override
  String yakuDetailClosedOpenHan(int closed, int open) {
    return '$closed han fermé · $open han ouvert';
  }

  @override
  String get yakuQuizPromptRiichiDefinition =>
      'Quel yaku se déclare en tenpai avec une main fermée après avoir déposé une mise de 1 000 points ?';

  @override
  String get yakuQuizExplanationRiichiDefinition =>
      'Le riichi se déclare en tenpai avec une main fermée et vaut 1 han.';

  @override
  String get yakuQuizPromptTanyaoDefinition =>
      'Quel yaku utilise uniquement les tuiles numérotées de 2 à 8, sans terminales ni honneurs ?';

  @override
  String get yakuQuizExplanationTanyaoDefinition =>
      'Le tanyao utilise uniquement les tuiles numérotées de 2 à 8, sans tuiles terminales ni honneurs.';

  @override
  String get yakuQuizPromptPinfuDefinition =>
      'Quel yaku exige une main fermée composée de suites, une paire sans valeur et une attente bilatérale ?';

  @override
  String get yakuQuizExplanationPinfuDefinition =>
      'Le pinfu est une main fermée composée de suites, avec une paire sans valeur et une attente bilatérale.';

  @override
  String get yakuQuizPromptYakuhaiDefinition =>
      'Quel yaku provient d\'un brelan ou d\'un carré de dragons, du vent du tour ou du vent du siège ?';

  @override
  String get yakuQuizExplanationYakuhaiDefinition =>
      'Un brelan ou un carré de dragons, du vent du tour ou du vent du siège vaut 1 han.';

  @override
  String get yakuQuizPromptIipeikouDefinition =>
      'Quel yaku utilise deux suites identiques de la même famille dans une main fermée ?';

  @override
  String get yakuQuizExplanationIipeikouDefinition =>
      'L\'iipeikou consiste en deux suites identiques de la même famille dans une main fermée.';

  @override
  String get yakuQuizPromptChitoitsuDefinition =>
      'Quel yaku est une main fermée composée de sept paires distinctes ?';

  @override
  String get yakuQuizExplanationChitoitsuDefinition =>
      'Chitoitsu est une main fermée composée de sept paires distinctes et vaut 2 han.';

  @override
  String get yakuQuizPromptToitoiDefinition =>
      'Quel yaku se compose de quatre brelans ou carrés et d\'une paire ?';

  @override
  String get yakuQuizExplanationToitoiDefinition =>
      'Toitoi se compose de quatre brelans ou carrés et d\'une paire ; il vaut 2 han, main ouverte ou fermée.';

  @override
  String get yakuQuizPromptSanshokuDefinition =>
      'Quel yaku utilise la même suite dans les trois familles numérotées ?';

  @override
  String get yakuQuizExplanationSanshokuDefinition =>
      'Sanshoku dōjun utilise la même suite dans les trois familles et vaut 2 han fermé ou 1 han ouvert.';

  @override
  String get yakuQuizPromptIkkitsukanDefinition =>
      'Quel yaku réunit 1-2-3, 4-5-6 et 7-8-9 dans une même famille ?';

  @override
  String get yakuQuizExplanationIkkitsukanDefinition =>
      'Ikkitsūkan réunit 1-2-3, 4-5-6 et 7-8-9 dans une même famille ; il vaut 2 han fermé ou 1 han ouvert.';

  @override
  String get yakuQuizPromptHonitsuDefinition =>
      'Quel yaku utilise une seule famille numérotée avec des tuiles d\'honneur ?';

  @override
  String get yakuQuizExplanationHonitsuDefinition =>
      'Honitsu utilise une seule famille numérotée avec des honneurs et vaut 3 han fermé ou 2 han ouvert.';

  @override
  String get yakuQuizPromptChinitsuDefinition =>
      'Quel yaku utilise une seule famille numérotée sans aucune tuile d\'honneur ?';

  @override
  String get yakuQuizExplanationChinitsuDefinition =>
      'Chinitsu utilise une seule famille numérotée sans honneurs et vaut 6 han fermé ou 5 han ouvert.';

  @override
  String get yakuQuizPromptHonitsuOpenHan =>
      'Combien vaut honitsu avec une main ouverte ?';

  @override
  String get yakuQuizExplanationHonitsuOpenHan =>
      'Honitsu vaut 2 han avec une main ouverte et 3 han avec une main fermée.';

  @override
  String get yakuQuizPromptChinitsuOpenHan =>
      'Combien vaut chinitsu avec une main ouverte ?';

  @override
  String get yakuQuizExplanationChinitsuOpenHan =>
      'Chinitsu vaut 5 han avec une main ouverte et 6 han avec une main fermée.';

  @override
  String get yakuQuizPromptSanshokuOpenHan =>
      'Combien vaut sanshoku dōjun avec une main ouverte ?';

  @override
  String get yakuQuizExplanationSanshokuOpenHan =>
      'Sanshoku dōjun vaut 1 han avec une main ouverte et 2 han avec une main fermée.';

  @override
  String get yakuQuizPromptJunchanClosedHan =>
      'Combien vaut junchan avec une main fermée ?';

  @override
  String get yakuQuizExplanationJunchanClosedHan =>
      'Junchan vaut 3 han avec une main fermée et 2 han avec une main ouverte.';

  @override
  String get yakuQuizPromptDoraIsYaku =>
      'Les dora suffisent-elles à elles seules pour remplir la condition de yaku nécessaire pour gagner ?';

  @override
  String get yakuQuizExplanationDoraIsYaku =>
      'Les dora ajoutent des han, mais ne sont pas un yaku. La main doit posséder au moins un yaku valable pour gagner.';

  @override
  String get yakuQuizPromptPinfuClosedOnly =>
      'Peut-on réaliser un pinfu avec une main ouverte ?';

  @override
  String get yakuQuizExplanationPinfuClosedOnly =>
      'Non. Le pinfu est un yaku réservé aux mains fermées.';

  @override
  String get yakuQuizPromptTanyaoAllowsHonors =>
      'Une main tanyao peut-elle contenir des tuiles d\'honneur ?';

  @override
  String get yakuQuizExplanationTanyaoAllowsHonors =>
      'Non. Le tanyao n\'accepte que les tuiles numérotées de 2 à 8 ; les honneurs et les terminales sont exclus.';
}
