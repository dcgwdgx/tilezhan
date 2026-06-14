/// 向听数（Shanten）计算 — 最小向听数与进张数分析。
///
/// 向听数表示手牌距离听牌/和牌还差几"向"：0 = 听牌，-1 = 和牌。
/// 同时提供[进张数]（有几种牌能让向听数减 1）用于评估牌效。
///
/// 本文件为引擎层的统一导入入口，实际实现在 [core/utils/shanten_calculator.dart]。
/// 上层模块应通过本路径引用，避免直接依赖 core/utils 的内部布局。
export '../../core/utils/shanten_calculator.dart';
