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
      '4-Fach-Quiz für alle 34 Steine.\nRichtig = verbraucht ein Herz.\nFalsch = kostenlos wiederholen.';

  @override
  String get onboarding2Title => 'Trainiere deine\nEffizienz';

  @override
  String get onboarding2Desc =>
      'Ziehe einen Stein und wähle\nden optimalen Abwurf.\nPerfekte Antworten werden belohnt.';

  @override
  String get onboarding3Title => 'Kostenlos starten';

  @override
  String get onboarding3Desc =>
      'Keine Anmeldung nötig.\n10 kostenlose Rätsel pro Tag.\nUnbegrenzt mit Pro freischalten.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Loslegen';

  @override
  String get homeDailyChallenge => 'TÄGLICHE HERAUSFORDERUNG';

  @override
  String get homeDailyDesc =>
      '3 Rätsel. Keine Ausdauerkosten. Hol dir deine Belohnung.';

  @override
  String get homeStartChallenge => '⚡ HERAUSFORDERUNG STARTEN';

  @override
  String get homeQuickAccess => 'SCHNELLZUGRIFF';

  @override
  String get homeFlashcards => 'Karteikarten';

  @override
  String get homeNanikiru => 'Nani-Kiru';

  @override
  String get homeScanner => 'Scanner';

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
  String get battlePremiumCTA => '4,99 \$/Monat — Unbegrenzt Spielen';

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
  String get battleComboSub => 'Jährlich -20% — 23,99 \$/Jahr';

  @override
  String get battleComboUnlock => 'FREISCHALTEN';

  @override
  String get battleDomain => 'tilezhan.app';

  @override
  String get premiumTitle => 'Wähle deinen Plan';

  @override
  String get premiumConnecting => 'Verbinde mit App Store...';

  @override
  String get premiumContinue => 'WEITER';

  @override
  String get premiumSelectPlan => 'PLAN AUSWÄHLEN';

  @override
  String get premiumPurchasing => 'KAUF LÄUFT...';

  @override
  String get premiumRestore => 'Käufe wiederherstellen';

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
    return 'Bester Abwurf: $discard  →  $count Typen, $types Akzeptanz-Steine';
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
  String get scannerTitle => 'Yaku Scanner';

  @override
  String get scannerDesc =>
      'Vollständiger Scan kommt in V2.\nDurchsuche die 10 Basis-Yaku unten.';

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
  String get flashcardPerfect => 'Perfect!';

  @override
  String get flashcardCorrect => 'Richtig';

  @override
  String get flashcardIncorrect => 'Falsch';

  @override
  String get flashcardTimeout => 'Timeout';

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
  String get settingsAnimation => 'Animation Speed';

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
}
