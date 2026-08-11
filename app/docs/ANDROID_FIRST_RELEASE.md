# Rainbow Cats Android 首版

本版本保持原小程序的四个主入口和九个页面层级，使用 Flutter 重建，并以本地 JSON 快照持久化取代微信云开发依赖。

## 页面

1. 首页
2. 任务列表
3. 发布任务
4. 任务详情
5. 商店列表
6. 上架商品
7. 商品详情
8. 我的/仓库
9. 物品详情

## 本地规则

- 胶囊菜单可在“卡比/瓦豆”之间切换。
- 只能完成对方发布的任务；完成后积分计入任务发布者。
- 只能购买对方发布且仍可用的商品；积分从当前身份扣除，物品进入当前身份仓库。
- 已使用的仓库物品不能恢复。
- 数据只保存在当前 Android 设备，不进行云同步。

## 构建

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK 输出：`app/build/app/outputs/flutter-apk/app-release.apk`。
