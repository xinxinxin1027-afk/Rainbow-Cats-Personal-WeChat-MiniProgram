#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 tool/import_original_assets.py
python3 tool/extract_original_style.py

if [[ ! -x android/gradlew ]]; then
  flutter create \
    --platforms=android \
    --project-name rainbow_cats \
    --org com.xinxinxin1027 \
    --no-pub \
    .
fi

# flutter create 会生成一个模板测试；本项目有自己的完整测试套件。
if [[ -f test/widget_test.dart ]] && grep -q 'MyApp' test/widget_test.dart; then
  rm -f test/widget_test.dart
fi

python3 tool/patch_android.py

# Launcher 图标必须走 Android 标准 mipmap/adaptive-icon 链，禁止再退回单张 drawable。
MANIFEST="android/app/src/main/AndroidManifest.xml"
grep -q 'android:icon="@mipmap/ic_launcher"' "$MANIFEST"
grep -q 'android:roundIcon="@mipmap/ic_launcher_round"' "$MANIFEST"
for resource in \
  android/app/src/main/res/mipmap-anydpi/ic_launcher.xml \
  android/app/src/main/res/mipmap-anydpi/ic_launcher_round.xml \
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml \
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml \
  android/app/src/main/res/drawable/ic_launcher_foreground.xml \
  android/app/src/main/res/values/colors.xml; do
  test -s "$resource"
done
grep -q '<adaptive-icon' android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
grep -q '<adaptive-icon' android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml
echo "ANDROID_LAUNCHER_ICON=PASS"

flutter pub get

# 上面的资源/样式生成器会重写 Dart 文件。统一在 bootstrap 末尾格式化，
# 保证随后严格的 `dart format --set-exit-if-changed` 是稳定、可重复的门禁。
dart format lib test integration_test >/dev/null
