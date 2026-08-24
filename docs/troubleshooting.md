# 故障排查

## 安卓启动找不到主活动类

错误示例：

```text
java.lang.ClassNotFoundException: Didn't find class
"com.tilezhan.app.MainActivity"
```

检查以下三处必须一致：

- `frontend/android/app/build.gradle.kts` 的 `namespace`
- 同一文件的 `applicationId`
- `frontend/android/app/src/main/kotlin/com/tilezhan/app/MainActivity.kt` 的 `package`

当前项目三处都应为 `com.tilezhan.app`，Kotlin 文件目录也必须与包路径一致。

如果代码正确但已安装旧包仍报错：

1. 卸载设备上的旧应用。
2. 删除旧的测试 APK/APKS。
3. 重新从同一提交构建。
4. 检查 APK 内容和 AndroidManifest 合并结果。
5. 确认上传 Google Play 的 AAB 不是修复前缓存产物。

## 应用包不能直接安装

AAB 是 Google Play 发布格式，不是普通设备安装包。可选方式：

- 使用工作流同时产出的 release APK。
- 把 AAB 上传到 Google Play 内部测试后从商店安装。
- 使用 `bundletool` 生成 APKS，再提取或安装设备对应 APK。

构建 AAB 本身不要求安装 `bundletool`。

## 本机为什么需要 Flutter

- 使用 GitHub Actions 构建和上传：本机不需要安装 Flutter。
- 本地运行、测试或构建：本机需要 Flutter 和对应平台工具链。
- 查看代码、修改文档、提交 Git：不需要 Flutter。

不要为了云端构建任务额外下载本地 Flutter；只有明确要做本地验证时才安装。

## 后端自动化在安装依赖时失败

常见信息：

```text
No matching distribution found for <包名>==<版本>
```

处理：

```powershell
Set-Location backend
python -m pip install --dry-run -r requirements.txt
```

确认版本在 Python 3.12 和目标平台真实存在，再修改固定版本。不要只因为本机已经装有其他版本，就认为自动化可以安装成功。

项目已修复过两个不存在版本：

- `google-cloud-firestore==2.18.1` 改为 `2.18.0`
- `mahjong==1.2.3` 改为 `1.2.1`

## 身份认证返回 401

检查：

- 客户端是否发送 `Authorization: Bearer <令牌>`。
- 令牌是否属于正确 Firebase 项目。
- 令牌是否过期或被撤销。
- 服务端 `FIREBASE_PROJECT_ID`、私钥和客户端邮箱是否匹配。
- 私钥换行是否正确还原。

不要用开启开发绕过的方式修复生产认证。生产环境会拒绝 `ALLOW_DEV_AUTH_BYPASS=true`。

## 服务端启动返回生产配置错误

当 `APP_ENV=production` 时必须满足：

- Firebase 项目 ID、私钥和客户端邮箱非空。
- RevenueCat webhook secret 非空。
- `DEBUG=false`。
- `ALLOW_DEV_AUTH_BYPASS=false`。

错误应在启动时修复配置，而不是删除安全校验。

## 商店商品查询不到

检查：

- 商品 ID 是否与代码逐字符一致。
- 商品是否在正确应用、正确平台下创建。
- 商品是否处于允许测试的状态。
- 测试账号是否有资格购买。
- 付款资料、税务和商家资料是否满足平台要求。
- 构建是否通过正确 `--dart-define` 开启销售。

当前客户端和后端商品 ID 不一致，默认销售关闭。在统一商品 ID 和完成端到端测试前，不应把“永久买断能配置”当成订阅也一定可以售卖的证明。

## 免费版本仍显示购买限制

确认构建参数：

```text
TZ_IAP_SALES_IOS=false
TZ_IAP_SALES_ANDROID=false
TZ_TRAINING_LIMITS_ENABLED=false
TZ_IAP_RESTORE_ENABLED=true
```

其中销售开关和训练限制开关相互独立。只关闭销售但仍开启训练限制，会导致免费用户仍受红心限制。

## 本地训练进度丢失或回退

检查应用日志中的 `StorageService` 读取或写入错误，并检查：

- 主 JSON 文件是否损坏。
- 同名 `.bak` 是否可恢复。
- 是否只剩 `.tmp`；读取逻辑不会把临时文件视为已提交数据。
- 是否在写入完成前退出页面或终止应用。
- 是否变更过存储键或模型结构但没有迁移。

不要直接删除用户数据作为首选修复。先备份应用目录并分析主文件、备份文件和版本字段。

## 客户端本地化编译错误

执行：

```powershell
Set-Location frontend
flutter gen-l10n
flutter analyze --no-fatal-infos
flutter test
```

常见原因：

- 三个 ARB 缺少同名 key。
- ARB 占位符参数不一致。
- 手工修改了生成文件。
- 方法使用了外层作用域中的本地化变量，iOS 提前编译无法接受。

解决后重新生成，不要直接修补 `lib/l10n/generated/`。

## 何切题库校验失败

执行：

```powershell
Set-Location frontend
dart run tool/validate_nanikiru_puzzles.dart
```

检查题目 ID、牌张数量、重复牌、答案、难度和教学标签。不要为了让校验通过而放宽规则，除非产品数据规范已经明确改变并有对应测试。

## 云端自动化通过但本地静态分析失败

当前工作流的分析命令带有非致命配置，部分流程还使用 `|| true`，可能不会阻断合并。本地仍应执行：

```powershell
flutter analyze --no-fatal-infos
```

目标是没有错误和警告；信息级提示可以单独规划治理。

## 文档或临时文件被误加入提交

先检查：

```powershell
git status --short
git diff --cached --name-only
```

只暂存确认的项目文件。不要使用会把整个工作区全部加入暂存区的命令。APK、AAB、APKS、keystore、下载工具、`.env` 和本地测试数据都不应提交。
