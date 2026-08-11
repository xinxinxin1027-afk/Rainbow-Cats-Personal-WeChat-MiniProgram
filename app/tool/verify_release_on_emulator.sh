#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

APK=build/app/outputs/flutter-apk/app-release.apk
AAPT=$(find "$ANDROID_HOME/build-tools" -name aapt -type f | sort -V | tail -1)
PACKAGE=$($AAPT dump badging "$APK" | sed -n "s/package: name='\([^']*\)'.*/\1/p" | head -1)

test -s "$APK"
test -x "$AAPT"
test -n "$PACKAGE"

assert_non_black() {
  image="$1"
  test -s "$image"
  python3 - "$image" <<'PY'
import sys
from PIL import Image, ImageStat

path = sys.argv[1]
with Image.open(path) as source:
    image = source.convert('RGB')
    stat = ImageStat.Stat(image)
    mean = sum(stat.mean) / 3.0
    extrema = image.getextrema()
    peak = max(channel[1] for channel in extrema)
    if mean < 18 and peak < 45:
        raise SystemExit(f'black-screen regression: {path}, mean={mean:.2f}, peak={peak}')
    print(f'NON_BLACK_SCREEN=PASS path={path} mean={mean:.2f} peak={peak}')
PY
}

launch_app() {
  adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/tmp/rainbow-monkey.log
}

current_pid() {
  adb shell pidof "$PACKAGE" | tr -d '\r'
}

rm -rf visual_review/release
mkdir -p visual_review/release
adb logcat -c
adb logcat -b crash -c >/dev/null 2>&1 || true
adb install -r "$APK"
adb shell am force-stop "$PACKAGE"
launch_app
sleep 4
initial_pid=$(current_pid)
printf '%s\n' "$initial_pid" | tee visual_review/release/pid.txt
test -n "$initial_pid"

size=$(adb shell wm size | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -1)
width=$(printf '%s\n' "$size" | awk '{print $1}')
height=$(printf '%s\n' "$size" | awk '{print $2}')
test -n "$width"
test -n "$height"
y=$((height - 110))

# 实际点击同一份 Release APK 的四个主入口并截图。
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
  assert_non_black "visual_review/release/$name.png"
  test -n "$(current_pid)"
done

# 重新冷启动到根页，再模拟用户按 Android 返回键离开 App。
# 正常行为是 moveTaskToBack：任务进入后台、Flutter 进程/路由仍保留。
adb shell am force-stop "$PACKAGE"
launch_app
sleep 3
root_pid=$(current_pid)
test -n "$root_pid"

cycle=1
while [ "$cycle" -le 3 ]; do
  adb shell input keyevent 4
  sleep 1
  background_pid=$(current_pid)
  test "$background_pid" = "$root_pid"
  launch_app
  sleep 2
  resumed_pid=$(current_pid)
  test "$resumed_pid" = "$root_pid"
  cycle=$((cycle + 1))
done
adb exec-out screencap -p > visual_review/release/resume-after-back.png
assert_non_black visual_review/release/resume-after-back.png

# Home 键也必须只把任务放到后台，重新点图标继续同一 Flutter 进程。
cycle=1
while [ "$cycle" -le 3 ]; do
  adb shell input keyevent 3
  sleep 1
  home_pid=$(current_pid)
  test "$home_pid" = "$root_pid"
  launch_app
  sleep 2
  resumed_pid=$(current_pid)
  test "$resumed_pid" = "$root_pid"
  cycle=$((cycle + 1))
done
adb exec-out screencap -p > visual_review/release/resume-after-home.png
assert_non_black visual_review/release/resume-after-home.png

# 用户从最近任务中真正结束/系统重建进程后，也必须可以干净冷启动。
adb shell am force-stop "$PACKAGE"
sleep 1
launch_app
sleep 3
cold_pid=$(current_pid)
test -n "$cold_pid"
adb exec-out screencap -p > visual_review/release/cold-restart.png
assert_non_black visual_review/release/cold-restart.png

adb logcat -d > visual_review/release/logcat.txt
adb logcat -b crash -d > visual_review/release/crash-logcat.txt 2>/dev/null || true

# Only Android's dedicated crash buffer is authoritative for this gate.
if grep -Fq "Process: $PACKAGE" visual_review/release/crash-logcat.txt; then
  echo 'Fatal crash found for release package:' >&2
  cat visual_review/release/crash-logcat.txt >&2
  exit 1
fi

printf 'package=%s\nsize=%sx%s\nrelease_install=PASS\nrelease_launch=PASS\nfour_tabs=PASS\nback_moves_task_to_background=PASS\nback_resume_same_process=PASS\nhome_resume_same_process=PASS\nresume_non_black=PASS\ncold_restart=PASS\ncrash_buffer=PASS\n' \
  "$PACKAGE" "$width" "$height" > visual_review/release/release-proof.txt
