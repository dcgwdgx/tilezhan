# 构建与发布

## 发布原则

- 正式产物优先由 GitHub Actions 构建，保证环境一致和过程可追溯。
- 合并到 `main` 之前必须通过 Pull Request 检查。
- 自动上传只表示产物进入商店后台，不代表已经通过审核或向所有用户发布。
- 商店状态、国家和地区、测试轨道、分阶段比例以控制台实时信息为准。
- 签名、服务账号和 App Store Connect 私钥只能保存在 GitHub Secrets 或受控密钥系统中。

## 版本规则

客户端版本来自 `frontend/pubspec.yaml`：

```yaml
version: 1.0.1+4
```

- `1.0.1` 是用户可见版本名。
- `4` 是本地声明的构建号。
- GitHub Android 工作流构建时用 `github.run_number` 覆盖构建号。
- iOS 工作流同样用 GitHub 运行编号作为构建号。

发布新用户可见版本时：

1. 更新 `pubspec.yaml` 版本名。
2. 更新根目录 `CHANGELOG.md`。
3. 确认商店版本名称、发行说明和应用内版本显示一致。
4. 不重复使用商店已经占用的构建号。

## 安卓自动构建

工作流：`.github/workflows/android-build.yml`

名称：`Android → Google Play`

触发方式：

- 推送到 `main`
- 手工触发

主要步骤：

1. 检出代码。
2. 安装 Flutter 3.44.1。
3. 获取依赖。
4. 运行完整 Flutter 测试。
5. 解码上传 keystore。
6. 构建 release AAB。
7. 构建 release APK。
8. 分别上传 AAB 和 APK 构建产物，保留 30 天。
9. 把 AAB 上传到 Google Play `internal` 轨道。

产物路径：

- `frontend/build/app/outputs/bundle/release/app-release.aab`
- `frontend/build/app/outputs/flutter-apk/app-release.apk`

所需 GitHub Secrets：

| 名称 | 用途 |
|---|---|
| `ANDROID_KEYSTORE_B64` | Base64 编码的 Android 上传 keystore |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 签名别名 |
| `ANDROID_KEY_PASSWORD` | 签名条目密码 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Google Play 服务账号 JSON 原文 |

工作流设置 `changesNotSentForReview: true`，并上传到内部测试轨道。进入正式版仍需要在 Google Play Console 中创建或推进正式发布、检查审核问题和覆盖国家/地区。

## 安卓本地构建

本地只在排错或预发布核验时需要 Flutter：

```powershell
Set-Location frontend
$env:ANDROID_KEYSTORE_PASSWORD = '<本地安全值>'
$env:ANDROID_KEY_ALIAS = '<本地安全值>'
$env:ANDROID_KEY_PASSWORD = '<本地安全值>'
flutter pub get
flutter test
flutter build appbundle --release
flutter build apk --release
```

`frontend/android/upload-keystore.jks` 必须由安全渠道放置，不得提交。

只通过 GitHub 构建和上传时，本机不需要安装 Flutter。`bundletool` 也不是生成 AAB 所必需；它只在需要把 AAB 转成可安装 APKS/APK、或做本地设备验证时使用。

## 苹果平台自动构建

工作流：`.github/workflows/ios-build.yml`

名称：`iOS → TestFlight`

触发方式：

- 推送到 `main`
- 手工触发

主要步骤：

1. 使用 macOS 15 和指定 Xcode。
2. 安装 Flutter 3.44.1。
3. 获取依赖。
4. 设置只支持 iPhone。
5. 创建临时 keychain 并导入证书、私钥和描述文件。
6. 构建未签名 archive。
7. 使用手工签名导出 IPA。
8. 通过 App Store Connect API key 上传 TestFlight。
9. 上传 IPA 构建产物并保留 30 天。

所需 GitHub Secrets：

| 名称 | 用途 |
|---|---|
| `APPLE_CERT_PEM_B64` | Base64 编码的发布证书 |
| `APPLE_KEY_PEM_B64` | Base64 编码的证书私钥 |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64 编码的描述文件 |
| `APPSTORE_KEY_ID` | App Store Connect API key ID |
| `APPSTORE_ISSUER_ID` | App Store Connect issuer ID |
| `APPSTORE_PRIVATE_KEY` | App Store Connect `.p8` 私钥内容 |

应用包名和描述文件必须匹配 `com.tilezhan.app`。TestFlight 上传成功后，正式版本仍需在 App Store Connect 中选择构建、填写版本信息并提交审核。

## 商业功能发布开关

默认自动构建没有传入销售开关，因此使用代码默认值：

- `TZ_IAP_SALES_IOS=false`
- `TZ_IAP_SALES_ANDROID=false`
- `TZ_TRAINING_LIMITS_ENABLED=false`
- `TZ_IAP_RESTORE_ENABLED=true`

结果是：关闭新销售、所有用户不限训练、移动端保留恢复购买。

重新开启销售不能只在工作流增加 `--dart-define`，必须先完成：

- 统一客户端、后端、RevenueCat 和两家商店的商品 ID。
- 配置月度、年度和永久商品及其价格。
- 确认 Google Play 收款资料可用。
- 验证 App Store 和 Google Play 沙盒购买。
- 验证恢复、取消、过期、退款和换机。
- 验证服务端权益可信校验。
- 更新隐私政策、商店数据安全和应用内购买说明。

当前商品 ID 不一致，详见 [服务端接口说明](api.md#订阅与产品)。在修复并完成测试前，不应开启新销售。

## 发布后核对

### 代码托管与自动化平台

- 所有自动化任务成功。
- 构建产物存在且大小合理。
- Android 和 iOS 使用预期提交。
- 没有密钥出现在日志或产物名称中。

### 谷歌应用商店

- AAB 的包名为 `com.tilezhan.app`。
- 版本号高于已上传版本。
- 当前轨道、国家/地区、审核状态正确。
- 应用图标、启动图标和商店图标一致。
- 崩溃、ANR 和预发布报告没有阻断问题。

### 苹果应用商店后台

- TestFlight 出现新的构建号。
- Bundle ID、签名和描述文件正确。
- 构建处理完成，没有出口合规或隐私缺项。
- 正式版本选择了正确构建并提交审核。

## 回滚

移动商店不能简单覆盖已发布构建号。出现严重问题时：

1. 暂停分阶段发布或停止推进审核。
2. 从已知正常提交创建修复分支。
3. 增加构建号，不能复用失败构建号。
4. 运行完整测试并重新构建上传。
5. 在版本变更记录中说明修复内容。

不要使用破坏性 Git 操作抹掉已经发布的历史提交。
