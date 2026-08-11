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
flutter pub get
