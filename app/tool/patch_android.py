#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import shutil

APP = Path(__file__).resolve().parents[1]
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
# 用户原图仍保留给 Android 12+ 启动画面；Launcher 本身优先使用 committed mipmap/adaptive 资源。
# 旧的最小工具测试夹具没有 launcher 资源，因此仅在资源齐备时切换到标准链。
launcher_probe = ANDROID / "app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"
if launcher_probe.is_file():
    text = text.replace('android:icon="@drawable/app_icon"', 'android:icon="@mipmap/ic_launcher"')
    if 'android:roundIcon=' not in text:
        text = text.replace(
            'android:icon="@mipmap/ic_launcher"',
            'android:icon="@mipmap/ic_launcher"\n        android:roundIcon="@mipmap/ic_launcher_round"',
            1,
        )
    else:
        text = text.replace(
            'android:roundIcon="@drawable/app_icon"',
            'android:roundIcon="@mipmap/ic_launcher_round"',
        )
else:
    text = text.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/app_icon"')
    text = text.replace(
        'android:roundIcon="@mipmap/ic_launcher_round"',
        'android:roundIcon="@drawable/app_icon"',
    )
manifest.write_text(text, encoding="utf-8")

png_source = APP / "assets/app_icon.png"
webp_source = APP / "assets/app_icon.webp"
if not png_source.is_file():
    raise SystemExit("缺少 assets/app_icon.png")
if not webp_source.is_file():
    raise SystemExit("缺少 assets/app_icon.webp")
icon_dir = ANDROID / "app/src/main/res/drawable-nodpi"
icon_dir.mkdir(parents=True, exist_ok=True)
stale_png = icon_dir / "app_icon.png"
if stale_png.exists():
    stale_png.unlink()
shutil.copyfile(webp_source, icon_dir / "app_icon.webp")

# 正式工程使用标准 Launcher 时要求整套资源齐全。
if launcher_probe.is_file():
    launcher_files = (
        ANDROID / "app/src/main/res/mipmap-anydpi/ic_launcher.xml",
        ANDROID / "app/src/main/res/mipmap-anydpi/ic_launcher_round.xml",
        ANDROID / "app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
        ANDROID / "app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml",
        ANDROID / "app/src/main/res/drawable/ic_launcher_foreground.xml",
        ANDROID / "app/src/main/res/values/colors.xml",
    )
    missing = [str(path.relative_to(ANDROID)) for path in launcher_files if not path.is_file()]
    if missing:
        raise SystemExit("缺少 Android Launcher 资源: " + ", ".join(missing))

# 根页面已移除小程序顶部栏，系统状态栏改为浅色背景 + 深色图标。
styles = ANDROID / "app/src/main/res/values/styles.xml"
if styles.exists():
    style_text = styles.read_text(encoding="utf-8")
    if '<item name="android:statusBarColor">#F6F6F6</item>' not in style_text:
        style_text = style_text.replace(
            '<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">',
            '<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">\n'
            '        <item name="android:statusBarColor">#F6F6F6</item>\n'
            '        <item name="android:windowLightStatusBar">true</item>\n'
            '        <item name="android:navigationBarColor">#FFFFFF</item>\n'
            '        <item name="android:windowLightNavigationBar">true</item>',
            1,
        )
    styles.write_text(style_text, encoding="utf-8")

launch = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item><color android:color="#FF99AA" /></item>
</layer-list>
'''
for folder in ("drawable", "drawable-v21"):
    target = ANDROID / f"app/src/main/res/{folder}/launch_background.xml"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(launch, encoding="utf-8")

# Android 12+ 启动画面继续使用原粉色和用户图标；Launcher 图标则使用 adaptive icon。
values_v31 = ANDROID / "app/src/main/res/values-v31/styles.xml"
values_v31.parent.mkdir(parents=True, exist_ok=True)
values_v31.write_text(
    '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowSplashScreenBackground">#FF99AA</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/app_icon</item>
        <item name="android:windowSplashScreenIconBackgroundColor">#FFF9FA</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:statusBarColor">#F6F6F6</item>
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:colorAccent">#FF99AA</item>
        <item name="android:navigationBarColor">#FFFFFF</item>
        <item name="android:windowLightNavigationBar">true</item>
    </style>
</resources>
''',
    encoding="utf-8",
)

# 根页返回只把任务移到后台，不销毁 Flutter 根路由；再次点桌面图标时保留当前内存状态。
main_activity = ANDROID / "app/src/main/kotlin/com/xinxinxin1027/rainbow_cats/MainActivity.kt"
main_activity.parent.mkdir(parents=True, exist_ok=True)
main_activity.write_text(
    '''package com.xinxinxin1027.rainbow_cats

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rainbow_cats/app_lifecycle",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveToBackground" -> result.success(moveTaskToBack(true))
                else -> result.notImplemented()
            }
        }
    }
}
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
