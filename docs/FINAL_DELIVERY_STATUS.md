# Android 最终交付状态

**FAIL**

- Run: https://github.com/xinxinxin1027-afk/Rainbow-Cats-Personal-WeChat-MiniProgram/actions/runs/31494666695
- Head: 3ffff0c3b27918d9a502af1bc242cf064d7273f3
- Failed steps:
  - deliver: Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs

```text
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.4531809Z INFO         | Increasing screen off timeout, logcat buffer size to 2M.
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.5714999Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell getprop sys.boot_completed
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.6054759Z 1
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.6092257Z Emulator booted.
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.6106451Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell input keyevent 82
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.6851020Z Disabling animations.
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.6881817Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell settings put global window_animation_scale 0.0
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.7515007Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell settings put global transition_animation_scale 0.0
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.7948665Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 shell settings put global animator_duration_scale 0.0
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.8313907Z ##[endgroup]
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:13.8349618Z [command]/usr/bin/sh -c sh app/tool/verify_release_on_emulator.sh
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.3110903Z Performing Streamed Install
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.3112188Z Success
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7918615Z args: [-p, com.xinxinxin1027.rainbow_cats, -c, android.intent.category.LAUNCHER, 1]
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7925722Z  arg: "-p"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7930588Z  arg: "com.xinxinxin1027.rainbow_cats"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7945685Z  arg: "-c"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7947967Z  arg: "android.intent.category.LAUNCHER"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7948784Z  arg: "1"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7949339Z data="com.xinxinxin1027.rainbow_cats"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:18.7950091Z data="android.intent.category.LAUNCHER"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:23.3347142Z 1876
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2368731Z args: [-p, com.xinxinxin1027.rainbow_cats, -c, android.intent.category.LAUNCHER, 1]
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2373674Z  arg: "-p"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2374403Z  arg: "com.xinxinxin1027.rainbow_cats"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2423458Z  arg: "-c"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2424141Z  arg: "android.intent.category.LAUNCHER"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2424604Z  arg: "1"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2424892Z data="com.xinxinxin1027.rainbow_cats"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:35.2425252Z data="android.intent.category.LAUNCHER"
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4588998Z Fatal crash found for release package.
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4642415Z ##[error]The process '/usr/bin/sh' failed with exit code 1
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4671384Z ##[group]Terminate Emulator
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4677286Z [command]/usr/local/lib/android/sdk/platform-tools/adb -s emulator-5554 emu kill
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4687017Z OK: killing emulator, bye bye
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4692842Z OK
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4693500Z ##[endgroup]
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4701936Z INFO         | Wait for emulator (pid 4651) 20 seconds to shutdown gracefully before kill;you can set environment variable ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL(in seconds) to change the default value (20 seconds)
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:37.4702860Z 
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:43.2573336Z INFO         | Saving with gfxstream=1
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:43.3284016Z INFO         | Saving snapshot 'default_boot' using 5838 ms
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:43.6019844Z ERROR        | stop: Not implemented
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:43.6021591Z WARNING      | Emulator client has not yet been configured.. Call configure me first!
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:43.6872007Z INFO         | removeAll
deliver	Install the exact Release APK on Pixel 6 API 35 and exercise four main tabs	2026-08-11T13:16:43.7485454Z WARNING      | Netsim Wifi dns:///localhost:39075 is gone due to Stream removed (CANCELLED)
```
