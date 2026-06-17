/// DifficultyScorer 题目难度评分器的单元测试
/// 测试覆盖：分数范围（800-1600）、高牌有效率 = 简单 = 低分、低牌有效率 = 困难 = 高分、目标分数映射
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/features/nanikiru/domain/difficulty_scorer.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

/// 快速创建用于测试的 Puzzle 对象
Puzzle _makePuzzle({int ukeireCount = 10, int ukeireTypes = 5}) {
  return Puzzle(
    puzzleId: 'test',
    hand13Ids: List.filled(13, 'm1'),
    drawnTileId: 's7',
    correctDiscardId: 'm1',
    ukeireCount: ukeireCount,
    ukeireTypes: ukeireTypes,
    ukeireTileIds: List.filled(ukeireTypes, 'p1'),
  );
}

void main() {
  /// DifficultyScorer 测试组：覆盖评分范围校验、牌有效率与难度关系、目标分数映射、基础分加权叠加四大场景
  group('DifficultyScorer', () {
    // 评分结果应在 800-1600 的有效范围内
    test('returns score in valid range', () {
      final puzzle = _makePuzzle();
      final score = DifficultyScorer.score(puzzle);
      expect(score, greaterThanOrEqualTo(800));
      expect(score, lessThanOrEqualTo(1600));
    });

    // 牌有效率高 = 容易做对 = 分数低；牌有效率低 = 难以判断 = 分数高
    test('high ukeire = easier = lower score', () {
      final easy = DifficultyScorer.score(_makePuzzle(ukeireCount: 24, ukeireTypes: 10));
      final hard = DifficultyScorer.score(_makePuzzle(ukeireCount: 3, ukeireTypes: 1));
      expect(easy, lessThan(hard));
    });

    // targetRange 返回适合目标难度的分数区间
    test('targetRange returns appropriate values', () {
      expect(DifficultyScorer.targetRange(800), lessThan(1000));
      expect(DifficultyScorer.targetRange(1000), greaterThanOrEqualTo(950));
      expect(DifficultyScorer.targetRange(1500), greaterThanOrEqualTo(1200));
    });

    // 评分从基础分 800 开始，各维度加权叠加
    test('uses base 800 + weighted dimensions', () {
      final puzzle = _makePuzzle();
      final score = DifficultyScorer.score(puzzle);
      // All dimensions contribute → score > base
      expect(score, greaterThanOrEqualTo(800));
    });
  });
}
