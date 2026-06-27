# TileZhan / TileSlash — Claude Code 行为指南

## 项目概览
- Flutter 日麻学习 App（闪卡+何切+役种+排行榜），iOS 已上架，Android 在审
- 前端 `frontend/`（Riverpod + GoRouter + Hive），后端 `backend/`（Python FastAPI + Firebase）
- i18n: en/fr/de，l10n 用 ARB + flutter gen-l10n，禁止新增硬编码英文字符串
- 测试: `flutter test`，部署到 251 服务器前必须先跑测试全绿
- iOS AOT compiler 比 JIT test 严格——`l10n` 在每个方法里都要 `AppLocalizations.of(context)!`，不能依赖外层 scope

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
