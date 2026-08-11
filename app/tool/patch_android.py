#!/usr/bin/env python3
from __future__ import annotations

import shutil
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
REPO = APP.parent
ANDROID = APP / "android"
manifest = ANDROID / "app/src/main/AndroidManifest.xml"
if not manifest.exists():
    raise SystemExit("AndroidManifest.xml 不存在，请先运行 flutter create")

text = manifest.read_text(encoding="utf-8")
permission = '<uses-permission android:name="android.permission.INTERNET" />'
root = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
if permission not in text:
    if root not in text:
        raise SystemExit("无法识别 AndroidManifest.xml 根节点")
    text = text.replace(root, f"{root}\n    {permission}", 1)
text = text.replace('android:label="rainbow_cats"', 'android:label="Rainbow Cats"')
if 'android:usesCleartextTraffic=' not in text:
    text = text.replace(
        'android:label="Rainbow Cats"',
        'android:label="Rainbow Cats"\n        android:usesCleartextTraffic="true"',
        1,
    )
manifest.write_text(text, encoding="utf-8")

# 尽量直接复用原小程序的 PNG 作为 Android 图标；找不到时保留 Flutter 默认图标。
mini = REPO / "miniprogram"
if mini.is_dir():
    pngs = sorted(
        (
            path
            for path in mini.rglob("*.png")
            if "tabbar" not in path.as_posix().lower()
            and "node_modules" not in path.parts
        ),
        key=lambda path: (
            0 if any(word in path.name.lower() for word in ("icon", "logo", "avatar")) else 1,
            len(path.parts),
            path.as_posix(),
        ),
    )
    if pngs:
        for density in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
            target = ANDROID / f"app/src/main/res/mipmap-{density}/ic_launcher.png"
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(pngs[0], target)

launch = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><color android:color="#FF99AA" /></item>
    <item>
        <bitmap android:gravity="center" android:src="@mipmap/ic_launcher" />
    </item>
</layer-list>
'''
for folder in ("drawable", "drawable-v21"):
    target = ANDROID / f"app/src/main/res/{folder}/launch_background.xml"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(launch, encoding="utf-8")

# Android 12+ 启动画面也保持原粉色，不出现突兀白屏。
values_v31 = ANDROID / "app/src/main/res/values-v31/styles.xml"
values_v31.parent.mkdir(parents=True, exist_ok=True)
values_v31.write_text(
    '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowSplashScreenBackground">#FF99AA</item>
        <item name="android:windowSplashScreenAnimatedIcon">@mipmap/ic_launcher</item>
        <item name="android:windowSplashScreenIconBackgroundColor">#FF99AA</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:colorAccent">#FF99AA</item>
        <item name="android:navigationBarColor">#FFFFFF</item>
    </style>
</resources>
''',
    encoding="utf-8",
)

# 可选正式签名；没有 Secrets 时 Flutter 生成的 debug 签名仍允许私人侧载。
gradle = ANDROID / "app/build.gradle.kts"
if gradle.exists():
    source = gradle.read_text(encoding="utf-8")
    marker = "// RAINBOW_OPTIONAL_SIGNING"
    if marker not in source:
        signing = r'''

// RAINBOW_OPTIONAL_SIGNING
val rainbowStoreFile = System.getenv("RAINBOW_KEYSTORE_PATH")
val rainbowStorePassword = System.getenv("RAINBOW_KEYSTORE_PASSWORD")
val rainbowKeyAlias = System.getenv("RAINBOW_KEY_ALIAS")
val rainbowKeyPassword = System.getenv("RAINBOW_KEY_PASSWORD")

android {
    if (!rainbowStoreFile.isNullOrBlank()) {
        signingConfigs {
            create("rainbowRelease") {
                storeFile = file(rainbowStoreFile)
                storePassword = rainbowStorePassword
                keyAlias = rainbowKeyAlias
                keyPassword = rainbowKeyPassword
            }
        }
        buildTypes {
            getByName("release") {
                signingConfig = signingConfigs.getByName("rainbowRelease")
            }
        }
    }
}
'''
        gradle.write_text(source.rstrip() + signing + "\n", encoding="utf-8")

print("ANDROID_PATCH=OK")
