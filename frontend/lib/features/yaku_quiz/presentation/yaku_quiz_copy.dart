import '../../../l10n/generated/app_localizations.dart';
import '../domain/yaku_quiz_question.dart';

/// 将领域层的稳定文案标识映射到生成的本地化访问器。
extension YakuQuizCopyLocalization on YakuQuizCopyKey {
  String localize(AppLocalizations l10n) => switch (this) {
        YakuQuizCopyKey.promptRiichiDefinition =>
          l10n.yakuQuizPromptRiichiDefinition,
        YakuQuizCopyKey.explanationRiichiDefinition =>
          l10n.yakuQuizExplanationRiichiDefinition,
        YakuQuizCopyKey.promptTanyaoDefinition =>
          l10n.yakuQuizPromptTanyaoDefinition,
        YakuQuizCopyKey.explanationTanyaoDefinition =>
          l10n.yakuQuizExplanationTanyaoDefinition,
        YakuQuizCopyKey.promptPinfuDefinition =>
          l10n.yakuQuizPromptPinfuDefinition,
        YakuQuizCopyKey.explanationPinfuDefinition =>
          l10n.yakuQuizExplanationPinfuDefinition,
        YakuQuizCopyKey.promptYakuhaiDefinition =>
          l10n.yakuQuizPromptYakuhaiDefinition,
        YakuQuizCopyKey.explanationYakuhaiDefinition =>
          l10n.yakuQuizExplanationYakuhaiDefinition,
        YakuQuizCopyKey.promptIipeikouDefinition =>
          l10n.yakuQuizPromptIipeikouDefinition,
        YakuQuizCopyKey.explanationIipeikouDefinition =>
          l10n.yakuQuizExplanationIipeikouDefinition,
        YakuQuizCopyKey.promptChitoitsuDefinition =>
          l10n.yakuQuizPromptChitoitsuDefinition,
        YakuQuizCopyKey.explanationChitoitsuDefinition =>
          l10n.yakuQuizExplanationChitoitsuDefinition,
        YakuQuizCopyKey.promptToitoiDefinition =>
          l10n.yakuQuizPromptToitoiDefinition,
        YakuQuizCopyKey.explanationToitoiDefinition =>
          l10n.yakuQuizExplanationToitoiDefinition,
        YakuQuizCopyKey.promptSanshokuDefinition =>
          l10n.yakuQuizPromptSanshokuDefinition,
        YakuQuizCopyKey.explanationSanshokuDefinition =>
          l10n.yakuQuizExplanationSanshokuDefinition,
        YakuQuizCopyKey.promptIkkitsukanDefinition =>
          l10n.yakuQuizPromptIkkitsukanDefinition,
        YakuQuizCopyKey.explanationIkkitsukanDefinition =>
          l10n.yakuQuizExplanationIkkitsukanDefinition,
        YakuQuizCopyKey.promptHonitsuDefinition =>
          l10n.yakuQuizPromptHonitsuDefinition,
        YakuQuizCopyKey.explanationHonitsuDefinition =>
          l10n.yakuQuizExplanationHonitsuDefinition,
        YakuQuizCopyKey.promptChinitsuDefinition =>
          l10n.yakuQuizPromptChinitsuDefinition,
        YakuQuizCopyKey.explanationChinitsuDefinition =>
          l10n.yakuQuizExplanationChinitsuDefinition,
        YakuQuizCopyKey.promptHonitsuOpenHan =>
          l10n.yakuQuizPromptHonitsuOpenHan,
        YakuQuizCopyKey.explanationHonitsuOpenHan =>
          l10n.yakuQuizExplanationHonitsuOpenHan,
        YakuQuizCopyKey.promptChinitsuOpenHan =>
          l10n.yakuQuizPromptChinitsuOpenHan,
        YakuQuizCopyKey.explanationChinitsuOpenHan =>
          l10n.yakuQuizExplanationChinitsuOpenHan,
        YakuQuizCopyKey.promptSanshokuOpenHan =>
          l10n.yakuQuizPromptSanshokuOpenHan,
        YakuQuizCopyKey.explanationSanshokuOpenHan =>
          l10n.yakuQuizExplanationSanshokuOpenHan,
        YakuQuizCopyKey.promptJunchanClosedHan =>
          l10n.yakuQuizPromptJunchanClosedHan,
        YakuQuizCopyKey.explanationJunchanClosedHan =>
          l10n.yakuQuizExplanationJunchanClosedHan,
        YakuQuizCopyKey.promptDoraIsYaku => l10n.yakuQuizPromptDoraIsYaku,
        YakuQuizCopyKey.explanationDoraIsYaku =>
          l10n.yakuQuizExplanationDoraIsYaku,
        YakuQuizCopyKey.promptPinfuClosedOnly =>
          l10n.yakuQuizPromptPinfuClosedOnly,
        YakuQuizCopyKey.explanationPinfuClosedOnly =>
          l10n.yakuQuizExplanationPinfuClosedOnly,
        YakuQuizCopyKey.promptTanyaoAllowsHonors =>
          l10n.yakuQuizPromptTanyaoAllowsHonors,
        YakuQuizCopyKey.explanationTanyaoAllowsHonors =>
          l10n.yakuQuizExplanationTanyaoAllowsHonors,
      };
}
