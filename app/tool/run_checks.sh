#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tool/static_source_check.py
bash tool/bootstrap_android.sh
dart format --output=none lib test integration_test
flutter analyze --fatal-infos
flutter test test/store_test.dart test/webdav_test.dart test/app_widget_test.dart test/layout_collision_test.dart
flutter test --update-goldens test/visual_review_test.dart
python3 tool/build_static_visual_review.py
flutter build apk --release
