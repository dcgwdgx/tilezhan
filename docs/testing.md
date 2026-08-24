# 测试与质量保证

## 质量目标

每次变更需要证明：

- 功能行为符合需求。
- 已有训练、存储和路由没有回归。
- 本地化代码可以生成并通过提前编译约束。
- 后端生产配置不会以不安全状态启动。
- 自动化环境可以真实安装所有依赖。
- 发布产物由测试通过的同一提交生成。

## 客户端检查

在 `frontend` 目录执行：

```powershell
flutter pub get
flutter gen-l10n
flutter analyze --no-fatal-infos
flutter test
```

完整测试覆盖率产物：

```powershell
flutter test --coverage --reporter expanded
```

何切题库检查：

```powershell
dart run tool/validate_nanikiru_puzzles.dart
flutter test test/nanikiru_catalog_test.dart
```

截至 `1.0.1+4` 文档基线，完整 Flutter 测试为 513 项通过。数量会随着用例变化，验收以当前命令全部通过为准，而不是固定数量。

## 服务端检查

在 `backend` 目录执行：

```powershell
python -m pip install --dry-run -r requirements.txt
python -m pytest -q
```

需要详细失败上下文时：

```powershell
python -m pytest tests/ -v --tb=short
```

截至 `1.0.1+4` 文档基线，后端测试为 81 项通过。

## 按变更选择测试

| 变更范围 | 最低要求 |
|---|---|
| ARB 或本地化调用 | `flutter gen-l10n`、完整 `flutter test` |
| 何切题库 | 题库工具、目录测试、加载器测试、完整测试 |
| SRS 或本地存储 | 对应领域测试、原子写入测试、完整测试 |
| 每日计划 | 生成器、Store、领域和首页组件测试 |
| 防守训练 | 目录、评估、进度、状态和页面测试 |
| 手牌分析 | 分析引擎、适配器、历史和页面测试 |
| 役种测验 | 目录、Provider 和页面测试 |
| 路由或首页 | 目标页面测试、首页测试和完整测试 |
| 商业功能 | 可用性、访问策略、IAP 状态和 Premium 页面测试 |
| 后端认证或配置 | 安全、配置、Firebase 和 API 测试 |
| 麻将引擎 | 向听数、有效牌和 API 边界测试 |
| 依赖版本 | 干净环境安装或 `pip --dry-run`，再运行完整测试 |
| 工作流 | 通过 Pull Request 验证对应 GitHub Actions |

## 云端自动化检查

### 后端自动化

`Backend CI` 在以下情况运行：

- Pull Request 修改 `backend/**`
- `main` 分支提交修改 `backend/**`

步骤：Python 3.12、安装 `requirements.txt`、运行后端测试。

### 客户端自动化

`Flutter Tests`：

- Flutter 3.44.1
- 获取依赖
- 静态分析
- 带覆盖率运行测试
- 上传 `lcov.info`

`Frontend CI/CD`：

- Flutter 3.44.1
- 获取依赖
- 静态分析
- 完整测试

目前两个工作流都把静态分析的信息级问题设为非致命，并且命令包含 `|| true`。这意味着自动化中的静态分析失败可能不会阻断合并；本地验收仍应确认没有错误和警告，后续建议收紧工作流。

## 测试数据与清理

部分 Hive 测试会在 `frontend/test/` 下生成 `.hive` 和 `.lock` 文件。测试结束后：

- 不要把运行时生成文件加入提交。
- 如果文件本来是跟踪的测试夹具，不要误删或覆盖。
- 清理前先用 `git status --short` 区分用户文件和生成文件。

## 文档变更验收

纯文档修改不需要重复运行全部业务测试，但必须执行：

- Markdown 相对链接检查
- `git diff --check`
- 版本号与配置项搜索核对
- 确认没有代码文件进入改动范围

如果文档修改同时改变工作流、配置或代码，则按实际代码范围运行测试，不能以“主要是文档”为理由跳过。

## 合并门槛

- 所有必需自动化检查通过。
- 没有未解释的测试跳过或失败。
- 没有提交密钥、构建产物或本地数据。
- 新功能有正常、错误、持久化和恢复路径测试。
- 用户可见文案覆盖三种语言。
- 对应中文文档和版本变更记录已经更新。
