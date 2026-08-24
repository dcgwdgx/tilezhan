# 项目行为指南（TileZhan / TileSlash）

## 项目概览
- Flutter 日麻学习 App，包含闪卡、何切、每日训练计划、防守训练、役种测验、手牌分析和排行榜
- 前端 `frontend/`（Riverpod + GoRouter + Hive，离线优先），后端 `backend/`（Python FastAPI + Firebase）
- 应用版本 `1.0.1+4`，包名 `com.tilezhan.app`；iOS/Android 审核与发布状态以商店控制台为准
- i18n: en/fr/de，l10n 用 ARB + flutter gen-l10n，禁止新增硬编码英文字符串
- 测试: 前端执行 `flutter test`，后端执行 `python -m pytest -q`；部署前必须全部通过
- 何切题库变更后执行 `dart run tool/validate_nanikiru_puzzles.dart`
- iOS AOT compiler 比 JIT test 严格——`l10n` 在每个方法里都要 `AppLocalizations.of(context)!`，不能依赖外层 scope
- 项目使用说明见根目录 `README.md`，详细功能边界见 `docs/features.md`

---

## 来自 Andrej Karpathy 的行为准则

### 1. 先想再写
- 不假设用户意图，不确定就问
- 多种方案时列出来，不悄悄选一个
- 有更简单的办法就说出来，该 push back 就 push back

### 2. 简单优先
- 最小代码解决需求，不写多余的抽象
- 不为不可能的场景写错误处理
- 200 行能减到 50 行就重写

### 3. 手术刀式改动
- 只改需求相关的代码，不碰相邻代码格式/注释
- 不重构没坏的东西
- 改动产生的副作用自己清理（无用 import 等）

### 4. 目标驱动
- 把模糊任务拆成可验证步骤
- 每步写完跑 `flutter test` 确认没崩
- 涉及 l10n 必跑 `flutter gen-l10n`
