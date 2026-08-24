# 客户端开发指南（TileZhan）

这是 TileZhan / TileSlash 的 Flutter 客户端。应用采用 Riverpod 管理状态、GoRouter 管理页面导航，并使用 Hive 保存训练、SRS、弱项和分析历史等设备本地数据。

## 环境要求

- Flutter `3.44.1`（GitHub Actions 使用的版本）
- Dart `>=3.2.0 <4.0.0`
- Android Studio / Android SDK，或 Xcode（按目标平台选择）

## 安装与运行

```powershell
Set-Location frontend
flutter pub get
flutter gen-l10n
flutter run
```

核心训练为离线优先设计，不要求本地后端始终在线。

## 主要模块

```text
lib/
├── core/                 认证、商业策略、SRS、存储、路由、网络等基础能力
├── features/
│   ├── flashcard/        闪卡复习
│   ├── nanikiru/         何切训练与自适应选题
│   ├── defense_trainer/  防守训练与进度
│   ├── hand_analyzer/    手牌分析和本地历史
│   ├── training_plan/    每日计划与弱项推荐
│   ├── yaku_quiz/        役种测验
│   └── ...               图鉴、个人资料、排行榜、设置等
├── l10n/                 ARB 源文件和生成的本地化代码
└── shared/               通用模型、牌效引擎和组件
```

功能之间的关系见 [功能与架构说明](../docs/features.md)。

完整开发、测试、数据和发布流程见 [项目文档中心](../docs/README.md)。

## 测试与静态检查

```powershell
flutter gen-l10n
flutter analyze --no-fatal-infos
flutter test
```

何切题库修改后还需要运行：

```powershell
dart run tool/validate_nanikiru_puzzles.dart
```

该工具校验题目 ID、答案、难度、教学标签和牌张结构，防止无效题目进入构建。

## 本地化

源文案位于：

- `lib/l10n/app_en.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_de.arb`

新增或修改用户可见文案时：

1. 在三个 ARB 文件中维护对应 key。
2. 执行 `flutter gen-l10n`。
3. 在使用文案的方法内通过 `AppLocalizations.of(context)!` 获取本地化对象。
4. 执行 `flutter test`，同时关注 iOS AOT 编译对作用域的严格检查。

不要手工编辑 `lib/l10n/generated/` 中的生成文件。

## 商业功能编译开关

商业功能由 `--dart-define` 控制，定义集中在 `lib/core/commerce/commerce_availability.dart`。

| 开关 | 默认值 | 作用 |
|---|---:|---|
| `TZ_IAP_SALES_IOS` | `false` | 是否在 iOS 展示并发起新购买 |
| `TZ_IAP_SALES_ANDROID` | `false` | 是否在 Android 展示并发起新购买 |
| `TZ_TRAINING_LIMITS_ENABLED` | `false` | 是否对非 Premium 用户启用红心和难度限制 |
| `TZ_IAP_RESTORE_ENABLED` | `true` | 是否允许移动端显式恢复历史购买 |

默认构建是完全免费且训练不限量的版本。启用某个平台的新销售示例：

```powershell
flutter build appbundle --release --dart-define=TZ_IAP_SALES_ANDROID=true
```

启用销售之前必须同时确认商店产品 ID、价格、购买恢复和服务端校验保持一致。商品 ID 不能为了绕过控制台冲突而随意改名。

## 本地构建

Android：

```powershell
flutter build appbundle --release
flutter build apk --release
```

iOS 构建和签名依赖 macOS、Xcode、证书及 provisioning profile：

```bash
flutter build ipa --release
```

正式产物通常由 GitHub Actions 生成；不要把 keystore、证书、私钥或服务账号 JSON 提交到仓库。

## 网络层状态

`lib/core/network/dio_client.dart` 提供统一请求、认证头、日志与请求接口。应用当前仍以设备本地训练为主；接入新的线上流程前，应先补全并验证实际后端地址、错误策略和重试实现，不能把占位逻辑当作已部署能力。

接口现状和生产化限制见 [服务端接口说明](../docs/api.md)。
