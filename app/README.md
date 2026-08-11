# Rainbow Cats Android

这是原 `Rainbow-Cats-Personal-WeChat-MiniProgram` 的轻量 Flutter Android 客户端。目标用户约 2～10 人，优先保持原小程序的页面层级、粉色顶栏、白色圆角卡片、原 Tab 图标和任务/商城/仓库逻辑，不引入企业级后端或冗余框架。

## 已实现

- 原四个主入口：`首页 / 任务 / 商城 / 仓库`。
- 原九个页面：列表、新增、详情、仓库物品详情。
- 任务、商品的新增、编辑、星标、搜索、删除和状态更新。
- 按原项目规则完成任务、增加发布者积分；兑换商品后扣当前成员积分并进入仓库。
- 2～10 名本地成员、身份切换、成员编辑和积分调整。
- 积分流水、本地持久化、损坏数据自动恢复、JSON 导入/导出。
- WebDAV 连接测试、建目录、上传、下载、合并同步、远端恢复和删除。
- 可选 Server URL、Bearer Token 与 `/health` 连通测试。
- 12 页 Golden / Emulator 视觉检查与 4 种窄屏尺寸碰撞测试。

## 本地开发

需要 Flutter 3.44.9、Java 17 和 Android SDK：

```bash
cd app
bash tool/bootstrap_android.sh
dart format lib test integration_test
flutter analyze --fatal-infos
flutter test \
  test/store_test.dart \
  test/webdav_test.dart \
  test/app_widget_test.dart \
  test/layout_collision_test.dart
flutter build apk --release
```

`bootstrap_android.sh` 会从仓库现有的 `miniprogram/` 自动复制原图片、Tab icon、页面标题、颜色和常用圆角，仓库已包含 Android/Gradle 文本配置；脚本会在缺少 wrapper 二进制时按固定 Flutter 版本补齐，并再次应用网络、启动页、图标和可选签名补丁。

## WebDAV 配置

打开任意页面右上角胶囊 → **设置与 WebDAV**，填写：

- WebDAV URL，例如 `https://example.com/remote.php/dav/files/name/`
- Username
- Password
- Remote Path，默认 `RainbowCats`
- File Name，默认 `rainbow-cats-data.json`

保存后可依次执行“测试连接”“上传备份”或“合并同步”。同步文件不包含 WebDAV 密码和 Server Token。HTTP 私有服务器也可以使用，但公网部署建议 HTTPS。

## GitHub Actions

- `android-ci.yml`：格式、分析、逻辑、WebDAV、页面、布局、Debug/Release APK。
- `visual-review.yml`：12 页 Golden 与 Pixel 6 / API 35 Emulator 截图。
- `android-release.yml`：重新执行全部门禁，构建同一份 APK，安装、启动、点击四个主入口、检查 Logcat，然后创建 GitHub Release。

正式签名可选配置四个 Secrets：

```text
RAINBOW_KEYSTORE_BASE64
RAINBOW_KEYSTORE_PASSWORD
RAINBOW_KEY_ALIAS
RAINBOW_KEY_PASSWORD
```

未配置时仍会生成可直接侧载安装的 APK；若需要后续版本无缝覆盖安装，应配置固定正式签名。

更多信息见根目录 `FINAL_REPORT.md` 与 `docs/ANDROID_FIRST_RELEASE.md`。
