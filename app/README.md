# Rainbow Cats Flutter Android

原微信小程序的轻量 Android 复刻。当前阶段只做 Android、本地双角色、本地持久化，不引入服务器和复杂架构；UI、逻辑和页面层级尽量保持原小程序一致。

## 本地运行

```bash
cd app
bash tool/bootstrap_android.sh
flutter run
```

`bootstrap_android.sh` 会从仓库现有 `miniprogram/` 自动提取原始图片、Tab icon、颜色与圆角，并在首次运行时生成标准 Android 平台壳。

## 检查与构建

```bash
bash tool/bootstrap_android.sh
flutter analyze
flutter test test/store_test.dart test/layout_collision_test.dart
flutter build apk --release
```

## 视觉复检

```bash
flutter test --update-goldens test/visual_review_test.dart
python3 -m pip install pillow
python3 tool/build_static_visual_review.py
```

GitHub Actions 还提供 Google Android Emulator 真机框架截图采集流程。

详细说明见 `docs/ANDROID_FIRST_RELEASE.md`。
