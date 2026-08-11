# Android 最终交付状态

**FAIL**

- Run: https://github.com/xinxinxin1027-afk/Rainbow-Cats-Personal-WeChat-MiniProgram/actions/runs/31493813026
- Head: e5c2e4489b9cb53a09068692f53c50daabc6ba44
- Failed steps:
  - deliver: Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs

```text
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:16.2472748Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:18.2555611Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:18.2882324Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:20.2955351Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:20.3358044Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:22.3444237Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:22.3798885Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:24.3888634Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:24.4381403Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:26.4472582Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:26.4774189Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:28.4842771Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:28.5123415Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.4952131Z INFO         | Boot completed in 38474 ms
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.4991923Z INFO         | Increasing screen off timeout, logcat buffer size to 2M.
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.5192524Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.5633333Z 1
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.5653861Z Emulator booted.
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.5755356Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell input keyevent 82
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.8064388Z Disabling animations.
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.8103086Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell settings put global window_animation_scale 0.0
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.8422688Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell settings put global transition_animation_scale 0.0
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.8802843Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell settings put global animator_duration_scale 0.0
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9171892Z ##[endgroup]
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9202846Z [command]/usr/bin/sh -c set -eu
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9261633Z [command]/usr/bin/sh -c cd app
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9325200Z [command]/usr/bin/sh -c APK=build/app/outputs/flutter-apk/app-release.apk
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9388996Z [command]/usr/bin/sh -c AAPT=$(find "$ANDROID_HOME/build-tools" -name aapt -type f | sort -V | tail -1)
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9640689Z [command]/usr/bin/sh -c PACKAGE=$($AAPT dump badging "$APK" | sed -n "s/package: name='\([^']*\)'.*/\1/p" | head -1)
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9675943Z /usr/bin/sh: 1: dump: not found
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9750048Z [command]/usr/bin/sh -c test -n "$PACKAGE"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9840844Z ##[error]The process '/usr/bin/sh' failed with exit code 1
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9855203Z ##[group]Terminate Emulator
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9855998Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 emu kill
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9891704Z OK: killing emulator, bye bye
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9921962Z OK
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9942842Z INFO         | Wait for emulator (pid 4618) 20 seconds to shutdown gracefully before kill;you can set environment variable ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL(in seconds) to change the default value (20 seconds)
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9952520Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:30.9976511Z ##[endgroup]
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:34.2765104Z INFO         | Saving with gfxstream=1
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:34.3418865Z INFO         | Saving snapshot 'default_boot' using 3342 ms
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:34.3904431Z ERROR        | stop: Not implemented
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:34.3905356Z WARNING      | Emulator client has not yet been configured.. Call configure me first!
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:34.4858479Z INFO         | removeAll
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:06:34.5407062Z WARNING      | Netsim Wifi dns:///localhost:42683 is gone due to CANCELLED
```
