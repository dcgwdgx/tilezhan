/// SM-2 间隔重复算法引擎 — TileZhan 卡片复习系统的核心计算模块。
///
/// SM-2 spaced repetition algorithm for TileZhan.
///
/// 本库提供闪卡复习系统所使用的核心 SRS 计算逻辑。设计上采用**无状态**模式——
/// 调用方自行持有每张卡片的全部状态并在每次调用时传入，这使得引擎极易于测试，
/// 也能无缝对接后端 API 进行同步。
///
/// This library provides the core SRS calculation used by the flashcard
/// review system. It is stateless by design — the caller owns all
/// per-card state and passes it in on each invocation, making the engine
/// trivially testable and backend-syncable.

/// SM-2（SuperMemo 2）间隔重复算法引擎。
///
/// SM-2 (SuperMemo 2) spaced repetition algorithm engine.
///
/// 实现经典的 SM-2 算法，根据** ease factor（难易度因子 EF）、重复次数和回忆质量**
/// 来计算下一次复习的时间间隔。输出三元组 `(newEf, newReps, newInterval)`，
/// 用于驱动前端的 SRS 卡片队列，并通过后端 API 持久化存储。
///
/// Implements the classic SM-2 algorithm for computing review schedules
/// based on ease factor (EF), repetition count, and recall quality.
/// The output tuple — (newEf, newReps, newInterval) — drives the
/// front-end SRS card queue and is persisted via the backend API.
///
/// 与后端实现严格一致:
/// Mirrors the backend implementation at
/// `app/domain/services/srs_service.py` exactly.
class SrsEngine {
  /// 根据单次复习结果计算下一轮 SRS 状态。
  ///
  /// Compute the next SRS state from a single review attempt.
  ///
  /// 参数说明：
  /// [ef]       — 当前难易度因子（ease factor），初始值通常为 2.5。
  ///               EF 越高表示卡片对用户而言越简单，复习间隔会越长。
  /// [reps]     — 本次复习之前**连续成功**的复习次数。
  ///               一旦某次评分 < 3 即归零。
  /// [interval] — 当前复习间隔（单位：天）。
  /// [quality]  — 用户自评的回忆质量，取值 0–5：
  ///   * 0 — 完全遗忘（complete blackout）
  ///   * 1 — 答错，但看到正确答案后觉得「原来如此」
  ///   * 2 — 答错，但看到正确答案后觉得「很简单，应该想起来」
  ///   * 3 — 答对，但回忆过程非常困难（serious difficulty）
  ///   * 4 — 答对，稍作犹豫后回忆起来（moment of hesitation）
  ///   * 5 — 完美作答，毫不费力（perfect, effortless recall）
  ///
  /// 返回值 `(newEf, newReps, newInterval)`：
  ///   * `newEf`       — 更新后的难易度因子（下限 1.3，避免间隔被压得过短）。
  ///   * `newReps`     — 更新后的连续成功次数（评分 < 3 则重置为 0）。
  ///   * `newInterval` — 下一次复习间隔（单位：天）。
  ///
  /// Returns `(newEf, newReps, newInterval)` where:
  ///   * `newEf` — updated ease factor (clamped to >= 1.3).
  ///   * `newReps` — reset to 0 on failure, otherwise incremented.
  ///   * `newInterval` — next review interval in days.
  static (double, int, int) calculate(
    double ef, int reps, int interval, int quality,
  ) {
    // ================================================================
    // 分支 1：回忆失败（quality < 3）
    // 评分 0/1/2 均视为本次复习未通过。
    // — EF 保持不变（不惩罚难易度因子）。
    // — 连续成功次数归零，下次从初始间隔重新开始。
    // — 间隔重置为 1 天，确保尽快重新复习。
    // ================================================================
    if (quality < 3) {
      // Failed recall — reset reps, keep EF
      return (ef, 0, 1);
    }

    // ================================================================
    // 分支 2：回忆成功（quality >= 3）
    // ================================================================

    // --- 步骤 A：更新难易度因子（EF）---
    // 标准 SM-2 公式：
    //   EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
    //
    // 其中 q = quality（3/4/5）。该公式的含义：
    //   - q = 5 → EF 增加 0.1（卡片更"简单"，间隔加速拉长）
    //   - q = 4 → EF 减少 0.14（略微变难）
    //   - q = 3 → EF 减少 0.22（明显变难，间隔增长放缓）
    //
    // 通过此项修正，系统对每张卡片的难易度持续校准。
    // Successful
    double newEf = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

    // --- 步骤 B：EF 下限裁剪 ---
    // 最低 1.3，防止极端低 EF 导致间隔被压缩到不合理的程度。
    // 注：SM-2 原始论文中未规定上限，实践中也无需上限。
    newEf = newEf < 1.3 ? 1.3 : newEf;

    // --- 步骤 C：递增连续成功次数 ---
    final newReps = reps + 1;

    // --- 步骤 D：计算下一次间隔 ---
    // 间隔采用分阶段策略：
    //   n = 1（首次成功）→ 1 天
    //   n = 2（第二次）  → 6 天
    //   n ≥ 3（第三次起）→ interval × EF（前次间隔乘以当前 EF，四舍五入）
    //
    // 前两次使用固定间隔是为了在初期建立稳定的记忆基础，
    // 之后再启用指数增长（EF 驱动的乘性扩展）。
    int newInterval;
    if (newReps == 1) {
      newInterval = 1;
    } else if (newReps == 2) {
      newInterval = 6;
    } else {
      // 乘性扩展核心：间隔 × EF，取整到最近天数
      newInterval = (interval * newEf).round();
    }

    // 返回更新后的三元组，由调用方持久化
    return (newEf, newReps, newInterval);
  }
}
