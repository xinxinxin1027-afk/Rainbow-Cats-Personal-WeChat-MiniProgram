#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/original
ROOT="$(cd .. && pwd)"
# 复用原微信小程序 TabBar 图标，文件名固定，Flutter 代码无需绑定微信路径。
for spec in \
  "HomeIconGrey.jpg tab_home_normal.jpg" "HomeIconColor.jpg tab_home_selected.jpg" \
  "MissionIconGrey.jpg tab_mission_normal.jpg" "MissionIconColor.jpg tab_mission_selected.jpg" \
  "MarketIconGrey.jpg tab_market_normal.jpg" "MarketIconColor.jpg tab_market_selected.jpg" \
  "AccountIconGrey.jpg tab_account_normal.jpg" "AccountIconColor.jpg tab_account_selected.jpg"; do
  set -- $spec
  src="$ROOT/miniprogram/images/TabBar/$1"
  [ -f "$src" ] && cp "$src" "assets/original/$2"
done
# 首页优先复用原图；找不到时由 Flutter 显示粉色占位视觉。
home="$(find "$ROOT/miniprogram" -type f \( -iname '*.jpg' -o -iname '*.png' \) ! -path '*/TabBar/*' | head -n 1 || true)"
[ -n "$home" ] && cp "$home" assets/original/home_0.jpg || true
# pubspec 声明了目录，因此确保目录永远有至少一个资源文件。
[ -e assets/original/home_0.jpg ] || cp assets/original/tab_home_normal.jpg assets/original/home_0.jpg 2>/dev/null || true
if [ ! -f android/app/src/main/AndroidManifest.xml ]; then
  flutter create --platforms=android --project-name rainbow_cats --org com.xinxinxin1027 .
fi
flutter pub get
