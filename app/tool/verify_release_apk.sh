#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
APK="${1:-build/app/outputs/flutter-apk/app-release.apk}"
OUT="visual_review/release"
mkdir -p "$OUT"
[[ -f "$APK" ]] || { echo "APK 不存在: $APK" >&2; exit 2; }

AAPT="$(find "${ANDROID_HOME:-$HOME/Android/Sdk}/build-tools" -name aapt -type f 2>/dev/null | sort -V | tail -1)"
[[ -x "$AAPT" ]] || { echo "找不到 aapt" >&2; exit 2; }
PACKAGE="$($AAPT dump badging "$APK" | sed -n "s/package: name='\([^']*\)'.*/\1/p" | head -1)"
[[ -n "$PACKAGE" ]] || PACKAGE="com.xinxinxin1027.rainbow_cats"

adb logcat -c
adb install -r "$APK"
adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 3
adb shell pidof "$PACKAGE" > "$OUT/pid.txt"
[[ -s "$OUT/pid.txt" ]] || { echo "应用启动失败" >&2; exit 3; }

read -r WIDTH HEIGHT < <(adb shell wm size | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -1)
for INDEX in 0 1 2 3; do
  X=$(( (2 * INDEX + 1) * WIDTH / 8 ))
  Y=$(( HEIGHT - 70 ))
  adb shell input tap "$X" "$Y"
  sleep 1
  adb exec-out screencap -p > "$OUT/tab-$INDEX.png"
done
adb shell uiautomator dump /sdcard/rainbow-window.xml >/dev/null
adb pull /sdcard/rainbow-window.xml "$OUT/window.xml" >/dev/null
adb logcat -d > "$OUT/logcat.txt"
if grep -E 'FATAL EXCEPTION|AndroidRuntime:.*Process: com\.xinxinxin1027\.rainbow_cats' "$OUT/logcat.txt"; then
  echo "发现运行时崩溃" >&2
  exit 4
fi
