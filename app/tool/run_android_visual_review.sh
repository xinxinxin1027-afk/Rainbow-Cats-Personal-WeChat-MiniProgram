#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="visual_review/emulator"
rm -rf "$OUT"
mkdir -p "$OUT"
flutter build apk --debug --dart-define=VISUAL_REVIEW=true
APK="build/app/outputs/flutter-apk/app-debug.apk"
AAPT="$(find "${ANDROID_HOME:-$HOME/Android/Sdk}/build-tools" -name aapt -type f 2>/dev/null | sort -V | tail -1)"
[[ -x "$AAPT" ]] || { echo "找不到 aapt" >&2; exit 2; }
PACKAGE="$($AAPT dump badging "$APK" | sed -n "s/package: name='\([^']*\)'.*/\1/p" | head -1)"
[[ -n "$PACKAGE" ]] || PACKAGE="com.xinxinxin1027.rainbow_cats"

# Release 可能使用固定正式签名；先卸载再装 debug 视觉包，避免签名冲突。
adb uninstall "$PACKAGE" >/dev/null 2>&1 || true
adb install "$APK" >/dev/null
adb logcat -c
adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 3
read -r WIDTH HEIGHT < <(
  adb shell wm size |
    sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' |
    tail -1
)
[[ -n "${WIDTH:-}" && -n "${HEIGHT:-}" ]] || {
  echo "无法读取模拟器尺寸" >&2
  exit 3
}
COUNT=12
for INDEX in $(seq 0 $((COUNT - 1))); do
  X=$(( (2 * INDEX + 1) * WIDTH / (2 * COUNT) ))
  Y=$(( HEIGHT / 2 ))
  adb shell input tap "$X" "$Y"
  sleep 1
  NAME=$(printf '%02d' $((INDEX + 1)))
  adb exec-out screencap -p > "$OUT/$NAME.png"
done
adb logcat -d > "$OUT/logcat.txt"
if grep -E 'FATAL EXCEPTION|AndroidRuntime:.*Process: com\.xinxinxin1027\.rainbow_cats' "$OUT/logcat.txt"; then
  echo "视觉巡检期间发现崩溃" >&2
  exit 5
fi
python3 tool/build_emulator_review.py
