# Rainbow Cats Android 首版

本版本在原仓库中新增 `app/` Flutter Android 客户端，同时完整保留原微信小程序。目标是先按原 UI、逻辑和页面层级完成 Android 复刻，再逐步优化。

## 页面层级

1. 首页 `MainPage`
2. 任务列表 `Mission`
3. 发布任务 `MissionAdd`
4. 任务详情 `MissionDetail`
5. 商店列表 `Market`
6. 上架商品 `MarketAdd`
7. 商品详情 `MarketDetail`
8. 我的/仓库 `Account`
9. 物品详情 `ItemDetail`

## 首版原则

- 只开发 Android，暂不包含 iOS。
- 保留粉色顶栏、白色圆角卡片、底部四栏、原 tab icon、原图片资源和主要间距/圆角风格。
- 使用 Flutter 单代码库实现页面。
- 使用 `shared_preferences` 保存很小规模的本地 JSON 数据，不引入数据库 ORM、网络框架或复杂状态管理。
- 胶囊菜单可在“卡比/瓦豆”之间切换。
- 只能完成对方发布的任务；完成后积分按原项目规则计入任务发布者。
- 只能购买对方发布且仍可用的商品；积分从当前身份扣除，物品进入当前身份仓库。
- 已使用的仓库物品不能再次使用。

## 原 UI 资源复用

`tool/import_original_assets.py` 会扫描根仓库 `miniprogram/`，把原 PNG/JPG/WebP/GIF 复制到 Flutter assets，并生成 `lib/generated/original_assets.dart`。

`tool/extract_original_style.py` 会读取 `app.json` 和 WXSS，提取导航主色、背景色、文字色和常用圆角，生成 `lib/generated/original_style.dart`。

## 构建

```bash
cd app
bash tool/bootstrap_android.sh
flutter analyze
flutter test test/store_test.dart test/layout_collision_test.dart
flutter build apk --release
```

APK 输出：`app/build/app/outputs/flutter-apk/app-release.apk`。

GitHub `main` 推送会自动运行 Android CI；`v*` 标签或手动运行 Android Release 工作流会生成通用 APK 和按 ABI 拆分 APK，并写入 GitHub Release。

## 视觉检查

- Widget Golden：393×852 固定视口覆盖 9 个页面。
- Layout Collision：320×568、360×640、393×852、411×891 覆盖 9 个页面。
- Android Emulator：Pixel 6 / API 35，自动安装调试 APK 并采集 9 页系统截图。
