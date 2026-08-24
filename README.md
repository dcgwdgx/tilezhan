# 项目说明（TileZhan / TileSlash）

TileZhan（商店名称 TileSlash）是一款面向日麻学习者的 Flutter 应用，通过闪卡、何切、防守训练、役种测验和手牌分析，把牌效率知识拆成可以每天完成的短训练。

- 应用包名：`com.tilezhan.app`
- 当前应用版本：`1.0.1+4`
- 客户端：Flutter、Riverpod、GoRouter、Hive
- 服务端：Python、FastAPI、Firebase / Firestore
- 本地化：英语、法语、德语
- 主要平台：iOS、Android

## 核心功能

- 闪卡与 SRS 间隔重复复习
- 何切训练、精确答案校验、难度评分和教学反馈
- 根据难度、弱项与题目多样性进行自适应选题
- 每日训练计划、连续完成记录和弱项推荐
- 筋牌、壁牌、现物等防守主题训练与进度跟踪
- 役种、番数和成立条件测验
- 手牌向听数、有效牌和弃牌候选分析，并保存设备本地历史
- 牌张图鉴、役种详情、个人资料和排行榜
- 英语、法语、德语本地化界面

完整功能边界和数据流见 [项目文档中心](docs/README.md)。

## 目录结构

```text
tilezhan/
├── frontend/          Flutter 客户端
├── backend/           FastAPI 服务端
├── docs/              产品功能与技术说明
├── .github/workflows/ 测试、Android 和 iOS 自动化流程
└── CHANGELOG.md       版本变更记录
```

## 快速开始

### 客户端

项目 CI 使用 Flutter `3.44.1`。本地安装兼容版本后执行：

```powershell
Set-Location frontend
flutter pub get
flutter gen-l10n
flutter run
```

应用的核心训练可以离线运行。网络功能需要另行配置并启动后端服务。客户端开发、测试、商业功能开关和构建命令见 [frontend/README.md](frontend/README.md)。

### 服务端

项目 CI 使用 Python `3.12`：

```powershell
Set-Location backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
python -m uvicorn app.main:app --reload
```

启动后可访问：

- 健康检查：`http://127.0.0.1:8000/health`
- OpenAPI：`http://127.0.0.1:8000/docs`

环境变量、Firebase 初始化和生产安全要求见 [backend/README.md](backend/README.md)。

## 测试和校验

### 客户端

```powershell
Set-Location frontend
flutter gen-l10n
flutter analyze --no-fatal-infos
flutter test
dart run tool/validate_nanikiru_puzzles.dart
```

### 服务端

```powershell
Set-Location backend
python -m pytest -q
```

提交到 `main` 或创建 Pull Request 时，GitHub Actions 会运行独立的 Flutter 测试、前端分析与测试、以及后端测试。

## 本地化约束

界面文案维护在以下 ARB 文件中：

- `frontend/lib/l10n/app_en.arb`
- `frontend/lib/l10n/app_fr.arb`
- `frontend/lib/l10n/app_de.arb`

不要在 Flutter 界面中新增硬编码英文字符串。修改 ARB 后必须执行：

```powershell
Set-Location frontend
flutter gen-l10n
flutter test
```

## 商业功能策略

商店销售和训练限制是两个独立的编译时开关。默认配置是：

- iOS 新销售关闭
- Android 新销售关闭
- 免费用户训练限制关闭，即所有用户可无限训练
- 移动端恢复购买入口开启

这样可以在暂时无法收款时发布完全免费的版本，同时保留历史购买恢复能力。具体开关见 [客户端开发指南](frontend/README.md#商业功能编译开关)。

## 自动构建与发布

合并到 `main` 会触发：

- `Backend CI`：Python 3.12 安装依赖并运行后端测试
- `Flutter Tests`：静态分析、测试和覆盖率产物
- `Frontend CI/CD`：Flutter 分析和测试
- `Android → Google Play`：运行测试、构建 AAB 与 APK，并上传 AAB 到 Google Play internal track
- `iOS → TestFlight`：构建签名 IPA、上传 TestFlight，并保留 IPA 构建产物

商店的审核和正式发布状态应以 App Store Connect 与 Google Play Console 为准，不在代码文档里写死。

## 相关文档

- [项目文档中心](docs/README.md)
- [Flutter 客户端开发指南](frontend/README.md)
- [FastAPI 服务端开发指南](backend/README.md)
- [功能与架构说明](docs/features.md)
- [系统架构](docs/architecture.md)
- [开发指南](docs/development.md)
- [服务端接口](docs/api.md)
- [数据与持久化](docs/data-storage.md)
- [测试与质量保证](docs/testing.md)
- [构建与发布](docs/release.md)
- [故障排查](docs/troubleshooting.md)
- [版本变更记录](CHANGELOG.md)
- [参与开发](CONTRIBUTING.md)
- [安全说明](SECURITY.md)
