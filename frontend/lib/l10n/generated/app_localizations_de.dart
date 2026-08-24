// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'TileSlash';

  @override
  String get appTagline => 'Meistere Mahjong, Stein für Stein';

  @override
  String get onboarding1Title => 'Meistere die\nStein-Erkennung';

  @override
  String get onboarding1Desc =>
      '4-Fach-Quiz für alle 34 Steine.\nRichtige Antworten sind immer kostenlos.\nFehler landen in deiner Wiederholung.';

  @override
  String get onboarding2Title => 'Trainiere deine\nEffizienz';

  @override
  String get onboarding2Desc =>
      'Ziehe einen Stein und wähle\nden optimalen Abwurf.\nPerfekte Antworten werden belohnt.';

  @override
  String get onboarding3Title => 'Tägliche\nLernroutine aufbauen';

  @override
  String get onboarding3Desc =>
      'Folge einem kurzen Plan, der sich an deine Wiederholungen und letzten Übungen anpasst.\nKeine Anmeldung erforderlich. Alle Trainings sind in dieser Version kostenlos.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Erste Lektion starten';

  @override
  String get homeDailyChallenge => 'TÄGLICHE HERAUSFORDERUNG';

  @override
  String get homeDailyDesc =>
      'Löse 3 Effizienzaufgaben ohne Ausdauerkosten und baue deine Tagesserie aus.';

  @override
  String get homeStartChallenge => '⚡ HERAUSFORDERUNG STARTEN';

  @override
  String get homeQuickAccess => 'SCHNELLZUGRIFF';

  @override
  String get homeFlashcards => 'Karteikarten';

  @override
  String get homeNanikiru => 'Nani-Kiru';

  @override
  String get homeDefenseTraining => 'Verteidigungstraining';

  @override
  String get homeScanner => 'Yaku-Nachschlagewerk';

  @override
  String get homeHandAnalyzer => 'Handanalyse';

  @override
  String get homeCollection => 'Yaku Guide';

  @override
  String get homeGraveyard => 'Friedhof';

  @override
  String get homeTileBrowser => 'Steine';

  @override
  String get homeProfile => 'Profil';

  @override
  String get homePremium => 'Premium';

  @override
  String get homeSettings => 'Einstellungen';

  @override
  String get homeRank => 'Rangliste';

  @override
  String get homeUpgrade => 'UPGRADE';

  @override
  String get homePro => 'PRO';

  @override
  String homeFreeCount(int count) {
    return '$count/3 kostenlos';
  }

  @override
  String homeHeartsRemaining(int count) {
    return 'Noch $count Herzen';
  }

  @override
  String dailyStreak(int count) {
    return '🔥 $count-Tage-Serie';
  }

  @override
  String dailyProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get dailyViewResult => 'HEUTIGES ERGEBNIS ANSEHEN';

  @override
  String get dailySummaryTitle => 'Tagesaufgabe abgeschlossen';

  @override
  String dailySummaryBody(int correct, int total, int accuracy, int streak) {
    return 'Du hast $correct/$total Aufgaben richtig gelöst.\nGenauigkeit: $accuracy%\nLernserie: $streak Tage';
  }

  @override
  String get trainingLoading => 'Der heutige Plan wird vorbereitet...';

  @override
  String get trainingLoadError =>
      'Der heutige Plan konnte nicht geladen werden. Du kannst es erneut versuchen, ohne gespeicherten Fortschritt zu verlieren.';

  @override
  String get trainingRetry => 'PLAN ERNEUT LADEN';

  @override
  String get trainingSaveError =>
      'Dein Fortschritt konnte nicht gespeichert werden. Prüfe den Gerätespeicher und versuche es erneut.';

  @override
  String get trainingSaveRetry => 'SPEICHERN ERNEUT VERSUCHEN';

  @override
  String get trainingTodayTitle => 'Heutiger 5-Minuten-Plan';

  @override
  String get trainingTodaySubtitle =>
      'Ein gezielter Weg auf Basis deiner Wiederholungen und letzten Übungen.';

  @override
  String trainingPlanProgress(int current, int total) {
    return '$current/$total abgeschlossen';
  }

  @override
  String get trainingStreakStart => 'Starte deine Lernserie';

  @override
  String trainingLearningStreak(int count) {
    return '🔥 $count Tage Lernserie';
  }

  @override
  String get trainingPlanComplete => 'PLAN ABGESCHLOSSEN';

  @override
  String get trainingStartPlan => 'HEUTIGEN PLAN STARTEN';

  @override
  String get trainingContinuePlan => 'PLAN FORTSETZEN';

  @override
  String get trainingTaskStarterTiles => 'Grundlegende Steine lernen';

  @override
  String get trainingTaskDueReview => 'Heutige Wiederholungen abschließen';

  @override
  String trainingTaskWeakSkill(String skill) {
    return '$skill stärken';
  }

  @override
  String get trainingTaskDailyEfficiency => 'Tägliche Effizienzaufgabe';

  @override
  String get trainingTaskExploreDefense => 'Defensives Lesen entdecken';

  @override
  String get trainingTaskExploreYaku => 'Yaku-Wissen entdecken';

  @override
  String get trainingTaskStarterDesc =>
      'Erkenne Steine mit drei kurzen Karteikarten sofort.';

  @override
  String trainingTaskDueDesc(int count) {
    return 'Wiederhole $count für heute geplante Aufgabe(n).';
  }

  @override
  String get trainingTaskDailyDesc =>
      'Triff drei Abwurfentscheidungen und vergleiche die Steineffizienz.';

  @override
  String get trainingTaskExploreDefenseDesc =>
      'Lerne, sichere Abwürfe anhand sichtbarer Hinweise einzuordnen.';

  @override
  String get trainingTaskExploreYakuDesc =>
      'Prüfe Definitionen und Regeln, die eine Gewinnerhand gültig machen.';

  @override
  String get trainingTaskWeakDesc =>
      'Übe gezielte Fragen aus diesem Schwachbereich.';

  @override
  String trainingTaskWeakEvidence(int correct, int attempts) {
    return 'Letzte Ergebnisse: $correct/$attempts richtig';
  }

  @override
  String get trainingSkillIsolatedTiles =>
      'Entscheidungen bei isolierten Steinen';

  @override
  String get trainingSkillTaatsuOverload => 'überladene Formen';

  @override
  String get trainingSkillPairProtection => 'Paarschutz';

  @override
  String get trainingSkillChiitoitsuChoice => 'Sieben-Paare-Entscheidungen';

  @override
  String get trainingSkillKokushiShape => 'Dreizehn-Waisen-Formen';

  @override
  String get trainingSkillTileEfficiency => 'Steineffizienz';

  @override
  String get trainingSkillGeneral => 'letzte Schwachbereiche';

  @override
  String get dailySummaryDone => 'Fertig';

  @override
  String get reviewFinish => 'Wiederholung beenden';

  @override
  String get battleTitle => 'Tagesbericht';

  @override
  String get battleTotal => 'Gesamt';

  @override
  String get battleAccuracy => 'Genauigkeit';

  @override
  String get battleMaxCombo => 'Max Combo';

  @override
  String get battleMistakeHint =>
      'Fehler jederzeit wiederholen — kostenlos, unbegrenzt';

  @override
  String get battlePremiumCTA => 'Premium-Optionen ansehen';

  @override
  String get battleMistakes => 'Fehler wiederholen';

  @override
  String get battleShare => 'Teilen';

  @override
  String get battleInvite => 'Einladen';

  @override
  String get battleMistakesBtn => 'Fehler';

  @override
  String get battleComboBanner => 'COMBO ×10!';

  @override
  String get battleComboSub =>
      'Sieh dir die derzeit im Store verfügbaren Optionen an';

  @override
  String get battleComboUnlock => 'OPTIONEN ANSEHEN';

  @override
  String get battleDomain => 'tilezhan.app';

  @override
  String get premiumTitle => 'Wähle deinen Plan';

  @override
  String get premiumConnecting =>
      'Verbindung mit dem Store wird hergestellt...';

  @override
  String get premiumContinue => 'WEITER';

  @override
  String get premiumSelectPlan => 'PLAN AUSWÄHLEN';

  @override
  String get premiumPurchasing => 'KAUF LÄUFT...';

  @override
  String get premiumRestore => 'Käufe wiederherstellen';

  @override
  String get premiumFreeReleaseTitle =>
      'Alle Trainings sind in dieser Version kostenlos';

  @override
  String get premiumFreeReleaseBody =>
      'Trainiere ohne Ausdauer- oder Schwierigkeitslimits. Deine Ergebnisse und Fehlerwiederholungen bleiben verfügbar.';

  @override
  String get premiumRestoreHint =>
      'Hast du in einer früheren Version etwas gekauft? Stelle hier deinen Kaufverlauf wieder her.';

  @override
  String get premiumRestoring => 'WIEDERHERSTELLUNG...';

  @override
  String get premiumRestoreRequested =>
      'Wiederherstellungsanfrage gesendet. Dein Zugang wird nach Bestätigung durch den Store aktualisiert.';

  @override
  String get premiumRestoreFailed =>
      'Käufe konnten nicht wiederhergestellt werden. Bitte versuche es erneut.';

  @override
  String get premiumNoProducts =>
      'Käufe sind vorübergehend nicht verfügbar. Der Store bietet derzeit keine Produkte an.';

  @override
  String get premiumUnavailable =>
      'Der Store ist vorübergehend nicht verfügbar. Bitte versuche es später erneut.';

  @override
  String get premiumRetry => 'ERNEUT VERSUCHEN';

  @override
  String get premiumPurchaseStarted =>
      'Kaufanfrage gesendet. Folge den Anweisungen des Stores, um fortzufahren.';

  @override
  String get premiumPurchaseFailed =>
      'Der Kauf konnte nicht gestartet werden. Bitte versuche es erneut.';

  @override
  String get premiumAllPlansHeader => 'Alle Bezahlpläne beinhalten:';

  @override
  String get premiumAllPlansFooter =>
      '✅ Unbegrenzte Rätsel   ✅ Geister-Modus (Fehlerreview)   ✅ Jederzeit kündbar';

  @override
  String get premiumFree => 'KOSTENLOS';

  @override
  String get premiumMonthly => 'MONATLICH';

  @override
  String get premiumAnnual => 'JÄHRLICH';

  @override
  String get premiumLifetime => 'LEBENSLANG';

  @override
  String get premiumPopular => '★ BELIEBT';

  @override
  String get premiumBestValue => 'BESTER PREIS — -50%';

  @override
  String get premiumPayOnce => 'EINMALZAHLUNG';

  @override
  String get premiumLaunchBanner =>
      'Launch-Angebot: Lebenslang -20% — Begrenzt';

  @override
  String get premiumPrivacy => 'Datenschutzerklärung';

  @override
  String get premiumTerms => 'Nutzungsbedingungen';

  @override
  String shareStats(Object total, Object accuracy, Object combo) {
    return '🎯 $total Rätsel heute · $accuracy% Genauigkeit · $combo× max Combo auf TileZhan! tilezhan.app';
  }

  @override
  String get inviteText =>
      '🀄 Komm zu TileZhan — meistere Mahjong! Kostenlose tägliche Rätsel. tilezhan.app';

  @override
  String get comboTitle => 'COMBO ×10!';

  @override
  String get comboSubtitle =>
      'Du bist on fire! Schalte unbegrenztes Spielen frei\nund halte deine Serie.';

  @override
  String get comboOffer => 'SONDERANGEBOT';

  @override
  String get comboDiscount => '-20%';

  @override
  String get comboUnlock => 'JETZT FREISCHALTEN — 23,99 \$';

  @override
  String get comboMaybe => 'Später';

  @override
  String get nanikiruDraw => 'Du hast gezogen:';

  @override
  String nanikiruCorrect(Object discard) {
    return 'Korrekter Abwurf: $discard';
  }

  @override
  String nanikiruYourDiscard(Object discard) {
    return 'Dein Abwurf: $discard';
  }

  @override
  String nanikiruBestDiscard(Object discard, Object count, Object types) {
    return 'Bester Abwurf: $discard  →  $types Arten, $count Akzeptanz-Steine';
  }

  @override
  String get nanikiruPerfectExplain =>
      'Maximiert die Stein-Akzeptanz — dieser Abwurf gibt dir die meisten Möglichkeiten, deine Hand zu vervollständigen.';

  @override
  String get nanikiruHint =>
      'Suche nach Sequenzen und Drillingen.\nWirf isolierte Steine ab.\nDie richtige Antwort maximiert die Akzeptanz (Ukeire).';

  @override
  String get nanikiruSkip => '🏳️ Überspringen';

  @override
  String get nanikiruConfirm => 'Bestätigen';

  @override
  String get nanikiruTapToContinue => 'Zum Fortfahren tippen';

  @override
  String get nanikiruPerfect => '🎯 PERFEKT!';

  @override
  String get nanikiruBlunder => '💥 FEHLER!';

  @override
  String get nanikiruAcceptanceTiles => 'Akzeptanz-Steine';

  @override
  String get nanikiruNextPuzzle => 'Nächstes Puzzle';

  @override
  String get nanikiruReviewAgain => 'Nochmal prüfen';

  @override
  String get nanikiruAcceptanceComparison => 'Akzeptanz-Vergleich';

  @override
  String get nanikiruYourDiscardLabel => 'Dein Abwurf';

  @override
  String get nanikiruBestDiscardLabel => 'Bester Abwurf';

  @override
  String get nanikiruSkippedTitle => 'ÜBERSPRUNGEN';

  @override
  String get nanikiruTimedOutTitle => 'ZEIT ABGELAUFEN!';

  @override
  String get nanikiruTopCandidatesTitle => 'Beste Abwurfoptionen';

  @override
  String get nanikiruBestBadge => 'BESTE WAHL';

  @override
  String get nanikiruSelectedBadge => 'DEINE WAHL';

  @override
  String get nanikiruTenpai => 'Tenpai';

  @override
  String nanikiruShantenValue(int shanten) {
    return '$shanten Shanten';
  }

  @override
  String nanikiruAcceptanceSummary(int types, int count) {
    return 'Arten: $types · Steine: $count';
  }

  @override
  String nanikiruUkeireLoss(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Akzeptanz-Steine weniger als beim besten Abwurf',
      one: '1 Akzeptanz-Stein weniger als beim besten Abwurf',
    );
    return '$_temp0';
  }

  @override
  String nanikiruShantenLoss(int shanten) {
    return 'Fällt um $shanten Shanten zurück';
  }

  @override
  String get nanikiruNoSelection => 'Kein Stein ausgewählt';

  @override
  String nanikiruTimeoutChoice(String discard) {
    return 'Auswahl bei Zeitablauf: $discard';
  }

  @override
  String get nanikiruSkillsTitle => 'Trainierte Fähigkeiten';

  @override
  String get nanikiruTypesLabel => 'Arten';

  @override
  String get nanikiruSkillIsolatedTile => 'Umgang mit isolierten Steinen';

  @override
  String get nanikiruSkillTaatsuOverload => 'Taatsu-Auswahl';

  @override
  String get nanikiruSkillPairProtection => 'Paare bewahren';

  @override
  String get nanikiruSkillChiitoitsu => 'Weg der sieben Paare';

  @override
  String get nanikiruSkillKokushi => 'Weg der dreizehn Waisen';

  @override
  String get nanikiruSkillGeneralEfficiency => 'Steineffizienz';

  @override
  String get nanikiruNotOptimalTitle => 'NICHT OPTIMAL';

  @override
  String get nanikiruDecisionLossTitle => 'Auswirkung der Entscheidung';

  @override
  String get nanikiruNoDecisionLoss => 'Beste Wahl — kein Effizienzverlust';

  @override
  String nanikiruRankLabel(int rank) {
    return 'Rang $rank';
  }

  @override
  String nanikiruDiscardLabel(String tile) {
    return 'Abwurf: $tile';
  }

  @override
  String get scannerTitle => 'Yaku-Nachschlagewerk';

  @override
  String get scannerDesc =>
      'Sieh dir die Yaku unten an oder öffne das Yaku-Dōjō, um dein Wissen zu testen.';

  @override
  String get scannerBasicYaku => 'BASIS YAKU';

  @override
  String get scannerFavorites => 'FAVORITEN';

  @override
  String get scannerBeginner => 'Anfänger';

  @override
  String get scannerIntermediate => 'Fortgeschritten';

  @override
  String get scannerAdvanced => 'Experte';

  @override
  String get scannerYakuman => 'Yakuman';

  @override
  String scannerYakuCount(int count) {
    return '$count Yaku';
  }

  @override
  String get handAnalyzerTitle => 'Handanalyse';

  @override
  String get handAnalyzerSubtitle =>
      'Gib eine geschlossene Hand mit 13 oder 14 Steinen für eine exakte Effizienzanalyse ein.';

  @override
  String get handAnalyzerScope =>
      'Nur reine Steineffizienz. Dora, Yaku, Punkte, sichtbare Steine, Rufe und Verteidigung werden nicht berücksichtigt.';

  @override
  String get handAnalyzerHand => 'DEINE HAND';

  @override
  String handAnalyzerTileCount(int count, int target) {
    return '$count / $target Steine';
  }

  @override
  String get handAnalyzerNeedTileCount =>
      'Gib genau 13 oder 14 Steine ein, um sie zu analysieren.';

  @override
  String get handAnalyzerFourCopyLimit =>
      'Ein Stein darf höchstens viermal vorkommen.';

  @override
  String get handAnalyzerRemoveHint =>
      'Tippe auf einen Stein in deiner Hand, um ihn zu entfernen.';

  @override
  String get handAnalyzerPicker => 'STEINE HINZUFÜGEN';

  @override
  String get handAnalyzerMan => 'Manzu';

  @override
  String get handAnalyzerPin => 'Pinzu';

  @override
  String get handAnalyzerSou => 'Souzu';

  @override
  String get handAnalyzerHonors => 'Ehrensteine';

  @override
  String get handAnalyzerAnalyze => 'Hand analysieren';

  @override
  String get handAnalyzerClear => 'Leeren';

  @override
  String get handAnalyzerCurrentShanten => 'Aktueller Shanten';

  @override
  String get handAnalyzerComplete => 'Vollständige Hand';

  @override
  String get handAnalyzerTenpai => 'Tenpai';

  @override
  String handAnalyzerShantenValue(int count) {
    return '$count-Shanten';
  }

  @override
  String get handAnalyzerImprovingTiles => 'Verbessernde Steine';

  @override
  String handAnalyzerEffectiveSummary(int types, int count) {
    return '$types Arten · $count Steine';
  }

  @override
  String get handAnalyzerDiscardCandidates => 'Abwurfkandidaten';

  @override
  String handAnalyzerCandidateSummary(String shanten, int types, int count) {
    return 'Nach Abwurf: $shanten · $types Arten · $count Steine';
  }

  @override
  String get handAnalyzerBest => 'BESTE WAHL';

  @override
  String handAnalyzerRank(int rank) {
    return 'Nr. $rank';
  }

  @override
  String get handAnalyzerNoImprovingTiles =>
      'In diesem Zustand gibt es keine verbessernden Steine.';

  @override
  String get handAnalyzerSave => 'Analyse speichern';

  @override
  String get handAnalyzerSaved => 'Unter den letzten Analysen gespeichert.';

  @override
  String get handAnalyzerRecent => 'LETZTE ANALYSEN';

  @override
  String get handAnalyzerRecentEmpty => 'Gespeicherte Hände erscheinen hier.';

  @override
  String get handAnalyzerOpen => 'Öffnen';

  @override
  String get handAnalyzerDelete => 'Löschen';

  @override
  String get handAnalyzerShapeBreakdown => 'Formen im Vergleich';

  @override
  String get handAnalyzerStandard => 'Standardhand';

  @override
  String get handAnalyzerSevenPairs => 'Sieben Paare';

  @override
  String get handAnalyzerThirteenOrphans => 'Dreizehn Waisen';

  @override
  String get handAnalyzerError =>
      'Diese Hand konnte nicht analysiert werden. Prüfe die Anzahl der Steine und versuche es erneut.';

  @override
  String get defenseTitle => 'Verteidigungstraining';

  @override
  String get defenseIntroTitle => 'Erkenne die Gefahr vor dem Abwurf';

  @override
  String get defenseIntroBody =>
      'Übe, anhand sichtbarer Hinweise den risikoärmsten Stein gegen einen Riichi-Gegner abzuwerfen.';

  @override
  String get defenseScope =>
      'Genbutsu ist nur gegen den Zielspieler sicher. Suji, Kabe und sichtbare Ehrensteine können Risiken verringern, garantieren aber niemals Sicherheit.';

  @override
  String defenseSessionLength(int count) {
    return 'Training mit $count Fragen';
  }

  @override
  String get defenseStart => 'Training starten';

  @override
  String defenseProgress(int current, int total) {
    return '$current von $total';
  }

  @override
  String get defenseQuestionPrompt =>
      'Welcher Abwurf hat in dieser Situation das geringste Risiko gegen den Zielspieler?';

  @override
  String defenseTargetRiver(String seat) {
    return 'Ablage des Riichi-Zielspielers · $seat';
  }

  @override
  String defenseOtherRiver(String seat) {
    return 'Andere Ablage · $seat';
  }

  @override
  String get defenseAdditionalVisible => 'WEITERE SICHTBARE STEINE';

  @override
  String defenseVisibleCopies(int count) {
    return '$count sichtbar';
  }

  @override
  String defenseVisibleTileSemantics(String tile, int count) {
    return '$tile, $count sichtbare Exemplare';
  }

  @override
  String defenseTileSemantics(String tile) {
    return 'Stein $tile';
  }

  @override
  String defenseNumberedTile(int number, String suit) {
    return '$number $suit';
  }

  @override
  String get defenseTileManSuit => 'Zeichen';

  @override
  String get defenseTilePinSuit => 'Kreise';

  @override
  String get defenseTileSouSuit => 'Bambus';

  @override
  String get defenseTileEastWind => 'Ostwind';

  @override
  String get defenseTileSouthWind => 'Südwind';

  @override
  String get defenseTileWestWind => 'Westwind';

  @override
  String get defenseTileNorthWind => 'Nordwind';

  @override
  String get defenseTileRedDragon => 'Roter Drache';

  @override
  String get defenseTileGreenDragon => 'Grüner Drache';

  @override
  String get defenseTileWhiteDragon => 'Weißer Drache';

  @override
  String get defenseChoicesTitle => 'WÄHLE EINEN ABWURF';

  @override
  String defenseChooseTile(String tile) {
    return '$tile wählen';
  }

  @override
  String get defenseLoadError =>
      'Die Verteidigungslektion konnte nicht geladen werden.';

  @override
  String get defenseRetry => 'Wiederholen';

  @override
  String get defenseTopicGenbutsu => 'Genbutsu';

  @override
  String get defenseTopicSuji => 'Suji';

  @override
  String get defenseTopicKabe => 'Kabe';

  @override
  String get defenseTopicHonorVisibility => 'Sichtbare Ehrensteine';

  @override
  String get defenseTopicCombinedEvidence => 'Kombinierte Hinweise';

  @override
  String get defenseSeatEast => 'Ost';

  @override
  String get defenseSeatSouth => 'Süd';

  @override
  String get defenseSeatWest => 'West';

  @override
  String get defenseSeatNorth => 'Nord';

  @override
  String get defenseGoodDecision => 'Gute Entscheidung';

  @override
  String get defenseReviewChoice => 'Überprüfe diese Wahl';

  @override
  String get defenseYourChoice => 'Deine Wahl';

  @override
  String get defenseRecommendedChoice => 'Empfohlene Wahl';

  @override
  String get defenseSelected => 'GEWÄHLT';

  @override
  String get defenseRecommended => 'EMPFOHLEN';

  @override
  String get defenseEvidenceTitle => 'Verteidigungshinweis';

  @override
  String get defenseRiskAbsoluteAgainstTarget =>
      'Gegen das Ziel sicher · Genbutsu';

  @override
  String get defenseRiskStronglyReducedNotAbsolute =>
      'Stark verringertes Risiko · nicht garantiert sicher';

  @override
  String get defenseRiskRelativelyReducedNotAbsolute =>
      'Hinweis auf geringeres Risiko · nicht garantiert sicher';

  @override
  String get defenseRiskNoEstablishedReduction =>
      'Keine belegte Risikominderung';

  @override
  String get defenseExplainTargetOwnDiscardIsGenbutsu =>
      'Dieser Stein liegt in der eigenen Ablage des Zielspielers. Furiten verhindert, dass dieser Spieler auf denselben Stein mit Ron gewinnt; über die anderen Spieler sagt das nichts aus.';

  @override
  String get defenseExplainOtherOpponentDiscardIsNotTargetGenbutsu =>
      'Dieser Stein liegt nur in der Ablage eines anderen Spielers und ist daher gegen das Ziel kein Genbutsu.';

  @override
  String get defenseExplainSujiCoversOnlyRyanmen =>
      'Die Ablage des Ziels liefert einen Suji-Hinweis, der einige beidseitige Sequenzwarten ausschließt. Tanki-, Shanpon-, Rand-, geschlossene und Spezialhand-Warten bleiben möglich.';

  @override
  String get defenseExplainCompleteKabeStillNotAbsolute =>
      'Vier sichtbare Exemplare bilden ein vollständiges Kabe und schließen den betreffenden Sequenzweg aus. Paar- und Spezialhand-Warten bleiben möglich.';

  @override
  String get defenseExplainIncompleteKabeLeavesSequencePossible =>
      'Drei Exemplare des Steins, der dieses unvollständige Kabe bildet, sind öffentlich sichtbar. Das vierte kann noch verdeckt sein; daher ist der Sequenzweg nicht vollständig ausgeschlossen.';

  @override
  String get defenseExplainThreeVisibleHonorHasKokushiException =>
      'Drei öffentliche Exemplare und dein Kandidat ergeben alle vier Steine. Eine gewöhnliche Paarwarte ist ausgeschlossen, doch eine Dreizehn-Waisen-Warte auf diesen Ehrenstein kann noch mit Ron gewinnen.';

  @override
  String get defenseExplainTwoVisibleHonorStillNotSafe =>
      'Bei zwei öffentlichen Exemplaren und dem Kandidaten in deiner Hand kann ein weiteres Exemplar noch verdeckt sein. Eine Tanki- oder Spezialhand-Warte bleibt möglich.';

  @override
  String get defenseExplainCombinedSujiAndKabeStillNotAbsolute =>
      'Suji und ein vollständiges Kabe verringern unabhängig voneinander gewöhnliche Sequenzwege, beweisen aber keine Sicherheit gegen Paar- oder Spezialhand-Warten.';

  @override
  String get defenseExplainTargetGenbutsuOutranksRelativeClues =>
      'Die eigene Ablage des Ziels schließt dessen Ron auf diesen Stein aus. Relative Suji-, Kabe- und Ehrenstein-Hinweise ersetzen kein Genbutsu.';

  @override
  String get defenseExplainNoEstablishedSafetyEvidence =>
      'Diese Lektion findet keinen Genbutsu-, Suji-, Kabe- oder Ehrenstein-Hinweis, der das Risiko dieses Steins gegen das Ziel senkt.';

  @override
  String get defenseNext => 'Nächste Frage';

  @override
  String get defenseViewSummary => 'Ergebnis ansehen';

  @override
  String get defenseSummaryTitle => 'Training abgeschlossen';

  @override
  String defenseSummaryScore(int correct, int total) {
    return '$correct von $total Entscheidungen entsprechen der Lektion.';
  }

  @override
  String defenseSummaryAccuracy(int accuracy) {
    return '$accuracy % richtig';
  }

  @override
  String get defenseSummaryBreakdown => 'FÄHIGKEITEN IM ÜBERBLICK';

  @override
  String defenseSummaryTopicScore(int correct, int total) {
    return '$correct / $total';
  }

  @override
  String get defenseTryAgain => 'Erneut versuchen';

  @override
  String get defenseReviewDone => 'Wiederholung beenden';

  @override
  String get defenseDone => 'Zurück zur Startseite';

  @override
  String get leaderboardTitle => 'Rangliste';

  @override
  String get leaderboardEmpty => 'Sei der Erste in der Rangliste!';

  @override
  String get leaderboardEmptySub =>
      'Löse Rätsel, um deinen Platz zu verdienen.';

  @override
  String get leaderboardRetry => 'Wiederholen';

  @override
  String get leaderboardMyRank => 'Mein Rang';

  @override
  String get leaderboardNotRanked => 'Spiele, um deinen Rang zu verdienen!';

  @override
  String get leaderboardEnterName => 'Gib deinen Namen ein';

  @override
  String get leaderboardNameHint => 'Dein Anzeigename';

  @override
  String get leaderboardSaveName => 'Speichern';

  @override
  String get flashcardTimer => 's';

  @override
  String get flashcardPerfect => 'Perfekt!';

  @override
  String get flashcardCorrect => 'Richtig';

  @override
  String get flashcardIncorrect => 'Falsch';

  @override
  String get flashcardTimeout => 'Zeit abgelaufen';

  @override
  String get flashcardPlayAgain => '🔄 Nochmal spielen';

  @override
  String get flashcardGotIt => 'Verstanden ✓';

  @override
  String get flashcardClose => 'Schließen';

  @override
  String get flashcardTapHint => 'Stein antippen für Hilfe';

  @override
  String get flashcardAccuracy => 'Genauigkeit';

  @override
  String get nanikiruNavTitle => 'Nani-Kiru · Effizienz';

  @override
  String get nanikiruDiscardHint => '1 Stein für max. Effizienz abwerfen';

  @override
  String get nanikiruEfficiencyScope =>
      'Reine Effizienz: ohne Dora, Yaku, Punkte, Spielsituation und Verteidigung.';

  @override
  String get nanikiruGotIt => 'Verstanden';

  @override
  String get nanikiruAcceptanceGridTitle => 'Akzeptanz-Steine';

  @override
  String get collectionTitle => 'Yaku-Sammlung';

  @override
  String get collectionClose => 'Schließen';

  @override
  String get collectionMastery => 'Meisterschaft';

  @override
  String get tileBrowserTitle => 'Steine';

  @override
  String get tileBrowserClose => 'Schließen';

  @override
  String get tileBrowserError => 'Fehler';

  @override
  String get commonGoBack => 'Zurück';

  @override
  String get commonNotFound => 'Nicht gefunden';

  @override
  String get settingsAppLanguage => 'Sprache';

  @override
  String get settingsLanguageSection => 'Sprache';

  @override
  String get profileTitle => 'Lernprofil';

  @override
  String get profileLocalProgress =>
      'Dein Lernfortschritt wird auf diesem Gerät gespeichert.';

  @override
  String get profileElo => 'Spielstärke';

  @override
  String get profileLearningStreak => 'Aktuelle Serie';

  @override
  String get profileBestStreak => 'Beste Serie';

  @override
  String get profileLearningSection => 'Lernfortschritt';

  @override
  String get profileTodayPlan => 'Heutiger Plan';

  @override
  String profileTodayProgress(int current, int total) {
    return '$current/$total Aktivitäten abgeschlossen';
  }

  @override
  String get profileReviewQueue => 'Wiederholungen';

  @override
  String profileReviewDue(int count) {
    return '$count heute fällig';
  }

  @override
  String get profileAccountSection => 'Frühere Käufe';

  @override
  String get profilePreferencesSection => 'Einstellungen';

  @override
  String get profileSettings => 'Einstellungen';

  @override
  String get profileSettingsDesc =>
      'Sprache, Käufe wiederherstellen, Datenschutz und Bedingungen';

  @override
  String get leaderboardKeepPlaying => 'Spiel weiter, um aufzusteigen!';

  @override
  String get leaderboardChangeName => 'Namen ändern';

  @override
  String get consentTitle => 'Globale Rangliste';

  @override
  String get consentBody =>
      'Deine Ergebnisse werden in die globale Rangliste hochgeladen. Dein Name ist für andere Spieler sichtbar. Du kannst deinen Namen jederzeit ändern.\n\nKeine weiteren persönlichen Daten werden erfasst. Siehe unsere Datenschutzerklärung.';

  @override
  String get consentAllow => 'Erlauben';

  @override
  String get consentNotNow => 'Später';

  @override
  String get flashcardSuitAll => '🎴 Alle';

  @override
  String get flashcardSuitMan => '🀇 Man';

  @override
  String get flashcardSuitPin => '🀙 Pin';

  @override
  String get flashcardSuitSou => '🀐 Sou';

  @override
  String get flashcardSuitHonor => '🀀 Ehre';

  @override
  String get flashcardAllTiles => 'Alle Steine';

  @override
  String flashcardSuiteFormat(Object suite) {
    return '$suite Karteikarten';
  }

  @override
  String get flashcardStudyHint =>
      '📖 Lerne die Hilfe, um diesen Stein zu merken';

  @override
  String flashcardFinishedStats(Object correct, Object wrong) {
    return '✅ $correct richtig · ❌ $wrong falsch';
  }

  @override
  String get nanikiruNew => 'NEU!';

  @override
  String get nanikiruDecision => '⏱ Entscheidung: ';

  @override
  String get nanikiruHandLabel => 'DEINE HAND · 14 STEINE';

  @override
  String get nanikiruSort => '📐 Sortieren';

  @override
  String get nanikiruHintTitle => '💡 Tipp';

  @override
  String nanikiruSessionCount(Object count) {
    return '⚔$count';
  }

  @override
  String get leaderboardYou => 'DU';

  @override
  String leaderboardStreak(Object count) {
    return '$count Serie';
  }

  @override
  String leaderboardElo(Object elo) {
    return '$elo ELO';
  }

  @override
  String get settingsLearning => 'Lernen';

  @override
  String get settingsDailyGoal => 'Tagesziel';

  @override
  String get settingsCountdown => 'Countdown';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsSignIn => 'Anmelden';

  @override
  String get settingsComingSoon => 'Demnächst';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAnimation => 'Animationsgeschwindigkeit';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsVersion => 'Version 1.0.0';

  @override
  String get rankNovice => 'Anfänger';

  @override
  String get rankApprentice => 'Lehrling';

  @override
  String get rankAdept => 'Kenner';

  @override
  String get rankExpert => 'Experte';

  @override
  String get rankMaster => 'Meister';

  @override
  String rankReviews(Object count) {
    return '$count Wiederholungen';
  }

  @override
  String get navHome => 'Start';

  @override
  String get navTiles => 'Steine';

  @override
  String get navYaku => 'Yaku';

  @override
  String get navReview => 'Review';

  @override
  String get graveyardSrsReview => 'SRS-Review';

  @override
  String get graveyardTodaysReview => 'HEUTIGE REVIEW';

  @override
  String graveyardReviewAll(int count) {
    return '⚡ Alle wiederholen ($count)';
  }

  @override
  String get graveyardWeaknessRadar => 'Schwächen-Radar';

  @override
  String graveyardWeakest(Object suit, Object rate) {
    return '⚠ Schwächste: $suit ($rate% Fehler)';
  }

  @override
  String get graveyardNothingDue =>
      'Nichts fällig!\nAlles auf dem neuesten Stand.';

  @override
  String graveyardErrorsOverdue(Object errors, Object days) {
    return '$errors Fehler · ${days}T überfällig';
  }

  @override
  String graveyardDueCount(int count) {
    return '$count FÄLLIG';
  }

  @override
  String get yakuQuizTitle => 'Yaku-Dōjō';

  @override
  String get yakuQuizSubtitle =>
      'Teste dein Wissen über Yaku und ihre Han-Werte.';

  @override
  String yakuQuizProgress(int current, int total) {
    return '$current von $total';
  }

  @override
  String get yakuQuizCorrect => 'Richtig!';

  @override
  String get yakuQuizIncorrect => 'Nicht ganz';

  @override
  String get yakuQuizExplanation => 'Erklärung';

  @override
  String get yakuQuizNext => 'Nächste Frage';

  @override
  String get yakuQuizFinish => 'Beenden';

  @override
  String get yakuQuizSummaryTitle => 'Training abgeschlossen';

  @override
  String yakuQuizSummaryBody(int correct, int total, int accuracy) {
    return 'Du hast $correct von $total Fragen richtig beantwortet.\nGenauigkeit: $accuracy %';
  }

  @override
  String get yakuQuizTryAgain => 'Noch einmal versuchen';

  @override
  String get yakuQuizTrue => 'Wahr';

  @override
  String get yakuQuizFalse => 'Falsch';

  @override
  String yakuQuizHanOption(int han) {
    return '$han Han';
  }

  @override
  String get yakuQuizStart => 'Training starten';

  @override
  String get yakuQuizTestMe => 'Teste mich';

  @override
  String get yakuQuizReviewDone => 'Wiederholung abschließen';

  @override
  String yakuDetailClosedHan(int han) {
    return '$han Han · nur geschlossen';
  }

  @override
  String yakuDetailClosedOpenHan(int closed, int open) {
    return '$closed Han geschlossen · $open Han offen';
  }

  @override
  String get yakuQuizPromptRiichiDefinition =>
      'Welches Yaku wird in Tenpai mit geschlossener Hand nach dem Setzen eines 1.000-Punkte-Stabs angesagt?';

  @override
  String get yakuQuizExplanationRiichiDefinition =>
      'Riichi wird mit einer geschlossenen Hand in Tenpai angesagt und zählt 1 Han.';

  @override
  String get yakuQuizPromptTanyaoDefinition =>
      'Welches Yaku verwendet nur Zahlensteine von 2 bis 8 und schließt Rand- und Ehrensteine aus?';

  @override
  String get yakuQuizExplanationTanyaoDefinition =>
      'Tanyao besteht nur aus Zahlensteinen von 2 bis 8; Rand- und Ehrensteine sind ausgeschlossen.';

  @override
  String get yakuQuizPromptPinfuDefinition =>
      'Welches Yaku erfordert eine geschlossene Hand aus Folgen, ein nicht wertendes Paar und eine beidseitige Warteform?';

  @override
  String get yakuQuizExplanationPinfuDefinition =>
      'Pinfu ist eine geschlossene Hand aus Folgen mit einem nicht wertenden Paar und einer beidseitigen Warteform.';

  @override
  String get yakuQuizPromptYakuhaiDefinition =>
      'Welches Yaku entsteht durch einen Drilling oder Vierling aus Drachen, Rundwind oder eigenem Platzwind?';

  @override
  String get yakuQuizExplanationYakuhaiDefinition =>
      'Ein Drilling oder Vierling aus einem Drachen, dem Rundwind oder dem eigenen Platzwind zählt 1 Han.';

  @override
  String get yakuQuizPromptIipeikouDefinition =>
      'Welches Yaku verwendet zwei identische Folgen derselben Farbe in einer geschlossenen Hand?';

  @override
  String get yakuQuizExplanationIipeikouDefinition =>
      'Iipeikou besteht aus zwei identischen Folgen derselben Farbe in einer geschlossenen Hand.';

  @override
  String get yakuQuizPromptChitoitsuDefinition =>
      'Welches Yaku ist eine geschlossene Hand aus sieben verschiedenen Paaren?';

  @override
  String get yakuQuizExplanationChitoitsuDefinition =>
      'Chitoitsu ist eine geschlossene Hand aus sieben verschiedenen Paaren und zählt 2 Han.';

  @override
  String get yakuQuizPromptToitoiDefinition =>
      'Welches Yaku besteht aus vier Drillingen oder Vierlingen und einem Paar?';

  @override
  String get yakuQuizExplanationToitoiDefinition =>
      'Toitoi besteht aus vier Drillingen oder Vierlingen und einem Paar; es zählt offen wie geschlossen 2 Han.';

  @override
  String get yakuQuizPromptSanshokuDefinition =>
      'Welches Yaku verwendet dieselbe Folge in allen drei Zahlenfarben?';

  @override
  String get yakuQuizExplanationSanshokuDefinition =>
      'Sanshoku Dōjun verwendet dieselbe Folge in allen drei Farben und zählt geschlossen 2 Han oder offen 1 Han.';

  @override
  String get yakuQuizPromptIkkitsukanDefinition =>
      'Welches Yaku verbindet 1-2-3, 4-5-6 und 7-8-9 in einer Farbe?';

  @override
  String get yakuQuizExplanationIkkitsukanDefinition =>
      'Ikkitsukan verbindet 1-2-3, 4-5-6 und 7-8-9 in einer Farbe; es zählt geschlossen 2 Han oder offen 1 Han.';

  @override
  String get yakuQuizPromptHonitsuDefinition =>
      'Welches Yaku verwendet eine Zahlenfarbe zusammen mit Ehrensteinen?';

  @override
  String get yakuQuizExplanationHonitsuDefinition =>
      'Honitsu verwendet eine Zahlenfarbe zusammen mit Ehrensteinen und zählt geschlossen 3 Han oder offen 2 Han.';

  @override
  String get yakuQuizPromptChinitsuDefinition =>
      'Welches Yaku verwendet nur eine Zahlenfarbe und keine Ehrensteine?';

  @override
  String get yakuQuizExplanationChinitsuDefinition =>
      'Chinitsu verwendet nur eine Zahlenfarbe und keine Ehrensteine; es zählt geschlossen 6 Han oder offen 5 Han.';

  @override
  String get yakuQuizPromptHonitsuOpenHan =>
      'Wie viele Han zählt Honitsu mit einer offenen Hand?';

  @override
  String get yakuQuizExplanationHonitsuOpenHan =>
      'Ein offenes Honitsu zählt 2 Han; ein geschlossenes Honitsu zählt 3 Han.';

  @override
  String get yakuQuizPromptChinitsuOpenHan =>
      'Wie viele Han zählt Chinitsu mit einer offenen Hand?';

  @override
  String get yakuQuizExplanationChinitsuOpenHan =>
      'Ein offenes Chinitsu zählt 5 Han; ein geschlossenes Chinitsu zählt 6 Han.';

  @override
  String get yakuQuizPromptSanshokuOpenHan =>
      'Wie viele Han zählt Sanshoku Dōjun mit einer offenen Hand?';

  @override
  String get yakuQuizExplanationSanshokuOpenHan =>
      'Ein offenes Sanshoku Dōjun zählt 1 Han; ein geschlossenes zählt 2 Han.';

  @override
  String get yakuQuizPromptJunchanClosedHan =>
      'Wie viele Han zählt Junchan mit einer geschlossenen Hand?';

  @override
  String get yakuQuizExplanationJunchanClosedHan =>
      'Ein geschlossenes Junchan zählt 3 Han; ein offenes Junchan zählt 2 Han.';

  @override
  String get yakuQuizPromptDoraIsYaku =>
      'Reichen Dora allein aus, um die zum Gewinnen nötige Yaku-Bedingung zu erfüllen?';

  @override
  String get yakuQuizExplanationDoraIsYaku =>
      'Dora erhöhen den Han-Wert, sind aber selbst keine Yaku. Die Hand braucht weiterhin mindestens ein gültiges Yaku.';

  @override
  String get yakuQuizPromptPinfuClosedOnly =>
      'Kann Pinfu mit einer offenen Hand erzielt werden?';

  @override
  String get yakuQuizExplanationPinfuClosedOnly =>
      'Nein. Pinfu ist nur mit einer geschlossenen Hand gültig.';

  @override
  String get yakuQuizPromptTanyaoAllowsHonors =>
      'Darf eine Tanyao-Hand Ehrensteine enthalten?';

  @override
  String get yakuQuizExplanationTanyaoAllowsHonors =>
      'Nein. Tanyao erlaubt nur Zahlensteine von 2 bis 8; Ehren- und Randsteine sind ausgeschlossen.';
}
