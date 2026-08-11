#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

APK=build/app/outputs/flutter-apk/app-release.apk
AAPT=$(find "$ANDROID_HOME/build-tools" -name aapt -type f | sort -V | tail -1)
PACKAGE=$($AAPT dump badging "$APK" | sed -n "s/package: name='\([^']*\)'.*/\1/p" | head -1)

test -s "$APK"
test -x "$AAPT"
test -n "$PACKAGE"

rm -rf visual_review/release
mkdir -p visual_review/release
adb logcat -c
adb logcat -b crash -c >/dev/null 2>&1 || true
adb install -r "$APK"
adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/tmp/rainbow-monkey.log
sleep 4
adb shell pidof "$PACKAGE" | tee visual_review/release/pid.txt
test -s visual_review/release/pid.txt

size=$(adb shell wm size | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -1)
width=$(printf '%s\n' "$size" | awk '{print $1}')
height=$(printf '%s\n' "$size" | awk '{print $2}')
test -n "$width"
test -n "$height"
y=$((height - 110))

for index in 0 1 2 3; do
  case "$index" in
    0) name=main ;;
    1) name=mission ;;
    2) name=market ;;
    3) name=account ;;
  esac
  x=$((width * (index * 2 + 1) / 8))
  adb shell input tap "$x" "$y"
  sleep 1
  adb exec-out screencap -p > "visual_review/release/$name.png"
  test -s "visual_review/release/$name.png"
  adb shell pidof "$PACKAGE" >/dev/null
done

adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 2
adb shell pidof "$PACKAGE" >/dev/null
adb logcat -d > visual_review/release/logcat.txt
adb logcat -b crash -d > visual_review/release/crash-logcat.txt 2>/dev/null || true

# Only Android's dedicated crash buffer is authoritative for this gate.
# The normal log buffer contains routine AndroidRuntime lines that can mention
# the app package and previously caused false positives despite a live process.
if grep -Fq "Process: $PACKAGE" visual_review/release/crash-logcat.txt; then
  echo 'Fatal crash found for release package:' >&2
  cat visual_review/release/crash-logcat.txt >&2
  exit 1
fi

printf 'package=%s\nsize=%sx%s\nrelease_install=PASS\nrelease_launch=PASS\nfour_tabs=PASS\ncrash_buffer=PASS\n' \
  "$PACKAGE" "$width" "$height" > visual_review/release/release-proof.txt
