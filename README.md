# Rainbow Cats / 彩虹猫情侣任务 App

这是原 **Rainbow Cats Personal WeChat MiniProgram** 的 Android Flutter 版本，同时完整保留原微信小程序源码。

当前项目定位很简单：**约 2～10 人的小范围使用，轻量、流畅、离线可用，不做大型商业 App 的复杂架构。**

## Android 直接安装

正式版本统一从 GitHub **Releases** 下载：

- `rainbow-cats-android-universal.apk`：推荐，绝大多数 Android 手机直接安装；
- `rainbow-cats-android-arm64-v8a.apk`：常见 64 位 Android 手机；
- `rainbow-cats-android-armeabi-v7a.apk`：旧 32 位设备；
- `rainbow-cats-android-x86_64.apk`：x86_64 模拟器/设备。

Release 同时提供 `SHA256SUMS.txt`、APK 签名信息、自动测试记录和视觉复检产物。

> Android 可能提示“允许安装未知应用”，这是 GitHub APK 侧载的正常系统提示。

## 已实现功能

- 保留原粉色 UI、卡片、圆角、底部四栏、原 Tab 图标与原页面层级；
- 首页、任务、发布任务、任务详情、商城、上架商品、商品详情、仓库、物品详情；
- 2～10 名成员与当前身份切换；
- 任务新增、编辑、搜索、星标、完成、删除；
- 积分变化与积分流水；
- 商品新增、编辑、兑换、删除；
- 仓库物品使用与历史；
- 本地持久化、数据损坏恢复、导入/导出/合并；
- WebDAV 真实连接、上传、下载、同步、恢复和远端删除；
- Server Base URL / Token / `/health` 客户端配置入口；
- 常见错误、空数据、无网络、错误 WebDAV 配置均有可恢复提示。

## WebDAV 配置

App 右上角胶囊菜单 → **设置与 WebDAV**：

1. 填写 WebDAV URL；
2. 填写 Username / Password；
3. 设置远程目录与文件名；
4. 点击 **测试连接**；
5. 保存后即可上传、下载或双向同步。

WebDAV 用于这个小规模 App 的备份/同步，不引入复杂服务器体系。真实密码和 Token 不写入 GitHub，备份文件也不会导出 WebDAV 密码或 Server Token。

## 项目结构

```text
app/                         Flutter Android 客户端
  lib/                       UI / Store / WebDAV / Settings
  test/                      业务、WebDAV、Widget、布局测试
  integration_test/          Android 集成流程
  android/                   Android/Gradle 配置
  tool/                      资源提取、构建与视觉复检脚本
miniprogram/                 原微信小程序（保留）
cloudfunctions/              原微信云函数（保留）
Pics/                        原版 UI 截图/说明资源
.github/workflows/           Android CI、视觉检查、Release
FINAL_REPORT.md              最终开发与验证报告
RELEASE_NOTES.md             Android Release 说明
```

## 开发与构建

```bash
cd app
bash tool/bootstrap_android.sh
flutter analyze --fatal-infos
flutter test test/store_test.dart
flutter test test/webdav_test.dart
flutter test test/app_widget_test.dart
flutter test test/layout_collision_test.dart
flutter build apk --release
```

CI 固定使用 Flutter 3.44.9 / Java 17，并在 GitHub Actions 中执行真实 Android 构建与 Pixel 6 / Android API 35 Emulator 验证。

## UI 还原原则

Android 首版不主动重新设计：优先复刻原微信小程序的颜色、圆角、间距、卡片、图标和页面层级。`Pics/` 中的原页面截图与 Emulator 截图用于视觉对照；后续优化在这一视觉基线上迭代。

## 原微信小程序

原 `miniprogram/` 与 `cloudfunctions/` 保留，可继续使用微信开发者工具查看。Android 客户端不依赖微信 OpenID/微信云环境，避免把小程序运行条件带到独立 APK。

## 文档

- `FINAL_REPORT.md`：完成情况、测试、架构、WebDAV、Release 与已知限制；
- `RELEASE_NOTES.md`：版本安装与功能说明；
- `docs/ANDROID_FIRST_RELEASE.md`：Android 首版开发说明。

源代码继续遵循仓库原有 MIT License；来自网络且授权不明确的旧图片资源仍应仅在明确拥有使用权的情况下分发。
