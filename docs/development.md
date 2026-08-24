# 开发指南

## 首次准备

建议在 Windows 上使用 PowerShell 7。客户端与服务端可以独立运行。

### 客户端

```powershell
Set-Location frontend
flutter --version
flutter doctor
flutter pub get
flutter gen-l10n
flutter test
```

自动化环境使用 Flutter `3.44.1`。如果本地版本不同，提交前至少确认依赖解析、代码生成和测试在自动化版本上兼容。

### 服务端

```powershell
Set-Location backend
python --version
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
Copy-Item .env.example .env
python -m pytest -q
```

自动化环境使用 Python `3.12`。不要把 `.env` 或虚拟环境提交到仓库。

## 日常开发流程

1. 从最新 `main` 创建功能分支。
2. 先确定可验证的目标和受影响模块。
3. 只修改需求相关文件，避免顺手重构相邻代码。
4. 修改用户文案时同步三个 ARB 文件并重新生成本地化代码。
5. 修改何切题库时运行题库校验工具。
6. 运行受影响模块测试，再运行完整测试。
7. 更新对应中文文档和版本变更记录。
8. 检查暂存清单，避免提交密钥、构建产物和本地临时文件。
9. 推送功能分支，通过 Pull Request 合并。

## 客户端开发规则

### 状态管理

- 共享状态通过 Riverpod Provider 暴露。
- 可测试的规则放在领域对象或 Notifier 中，不直接写进组件回调。
- 异步写入需要明确等待或刷新，避免页面状态领先于磁盘状态。
- 测试中通过可注入存储或内存存储隔离文件系统。

### 路由

- 新页面在 `core/router/app_router.dart` 注册。
- 路由参数必须有缺省和异常处理。
- 修改路由后至少增加页面可达性测试。

### 本地化

源文件：

- `lib/l10n/app_en.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_de.arb`

修改流程：

```powershell
flutter gen-l10n
flutter test
```

不要手工编辑 `lib/l10n/generated/`。iOS 提前编译比普通测试更严格，在每个使用本地化对象的方法中直接获取 `AppLocalizations.of(context)!`，不要依赖不安全的外层作用域。

### 何切题库

题库路径：`assets/data/nanikiru_puzzles.json`。

```powershell
dart run tool/validate_nanikiru_puzzles.dart
flutter test test/nanikiru_catalog_test.dart
flutter test test/static_puzzle_loader_test.dart
```

题目 ID 必须唯一；答案、牌张数量、同牌张数、难度和教学标签必须通过校验。

## 后端开发规则

### 配置

- 配置统一在 `app/config.py` 声明。
- 新增配置时同步 `.env.example` 和 `backend/README.md`。
- 生产必需配置加入启动校验，不在首次请求时才暴露错误。
- 密钥只通过环境变量或部署平台密钥管理传入。

### 接口

- 业务接口使用 `/api/v1` 前缀。
- 需要用户身份的接口依赖 `get_current_user`。
- 新增请求结构优先使用 Pydantic 模型，不使用无约束字典接收关键数据。
- 对外错误信息不暴露底层异常、令牌或服务账号内容。
- 修改接口后同步 [服务端接口](api.md) 和对应测试。

### 依赖

固定新版本前先验证版本真实存在：

```powershell
python -m pip install --dry-run -r requirements.txt
```

然后在干净 Python 3.12 环境完成一次安装和测试。

## 文档更新对应关系

| 代码变化 | 必须检查的文档 |
|---|---|
| 新增功能或改变玩法 | `features.md`、`CHANGELOG.md` |
| 新增页面或改变模块关系 | `architecture.md` |
| 新增或改变接口 | `api.md`、`backend/README.md` |
| 新增存储键或数据版本 | `data-storage.md` |
| 修改测试命令或门槛 | `testing.md` |
| 修改构建、密钥或商店轨道 | `release.md` |
| 新增常见故障 | `troubleshooting.md` |

## 提交前检查

```powershell
git status --short
git diff --check
```

确认不存在以下内容：

- `.env`、Firebase 私钥、RevenueCat 密钥
- Android keystore、签名密码
- Apple 证书、私钥、描述文件、App Store Connect 私钥
- APK、AAB、IPA、APKS、覆盖率和临时下载目录
- 测试运行生成的 Hive、锁文件或缓存文件
