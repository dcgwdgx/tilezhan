import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/srs/srs_provider.dart';
import '../../defense_trainer/data/defense_progress_store.dart';
import '../../nanikiru/domain/nanikiru_skill_mastery_provider.dart';
import 'training_plan_store.dart';

/// A persistence barrier for one accepted training answer.
///
/// Every learning notifier updates memory synchronously and writes in its own
/// serial queue. Screens call this before advancing or leaving feedback so a
/// successful UI transition never outruns the durable daily-plan/SRS writes.
final trainingProgressPersistenceProvider =
    Provider<TrainingProgressPersistence>((ref) {
  return TrainingProgressPersistence(ref);
});

class TrainingProgressPersistence {
  const TrainingProgressPersistence(this._ref);

  final Ref _ref;

  Future<void> flush({
    bool includeNanikiruMastery = false,
    bool includeDefenseProgress = false,
  }) async {
    // Exact-review screens separately defer their SRS mutation until the plan
    // flush below succeeds. For ordinary answers this method is a completion
    // barrier; it does not claim atomicity across independent storage keys.
    await _ref.read(dailyTrainingPlanProvider.notifier).flush();
    await _ref.read(srsNotifierProvider.notifier).flush();
    if (includeNanikiruMastery) {
      await _ref.read(nanikiruSkillMasteryProvider.notifier).flush();
    }
    if (includeDefenseProgress) {
      await _ref.read(defenseProgressProvider.notifier).flush();
    }
  }
}
