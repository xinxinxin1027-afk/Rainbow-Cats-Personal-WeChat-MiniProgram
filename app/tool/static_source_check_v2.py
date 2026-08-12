#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
ROOT = APP.parent
ERRORS: list[str] = []


def fail(message: str) -> None:
    ERRORS.append(message)


def check_local_imports(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for target in re.findall(r"^(?:import|export)\s+['\"]([^'\"]+)['\"]", text, re.M):
        if target.startswith(("dart:", "package:")):
            continue
        if not (path.parent / target).resolve().exists():
            fail(f"{path.relative_to(ROOT)} 引用不存在: {target}")


for dart in sorted(APP.rglob("*.dart")):
    check_local_imports(dart)
    text = dart.read_text(encoding="utf-8")
    for forbidden in (
        "UnimplementedError",
        "throw UnsupportedError",
        "敬请期待",
        "开发中",
        "FontWeight.w650",
        "FontWeight.w750",
    ):
        if forbidden in text:
            fail(f"{dart.relative_to(ROOT)} 含禁止内容: {forbidden}")

pages_path = APP / "lib/src/pages_v2.dart"
if not pages_path.exists():
    fail("缺少 pages_v2.dart")
    pages = ""
else:
    pages = pages_path.read_text(encoding="utf-8")

match = re.search(r"pageNames\s*=\s*<String>\[(.*?)\];", pages, re.S)
if not match:
    fail("无法读取视觉页面名称")
else:
    count = len(re.findall(r"'[^']+'", match.group(1)))
    if count != 11:
        fail(f"视觉页面必须为 11 个，实际 {count}")

main = (APP / "lib/main.dart").read_text(encoding="utf-8")
if "/members" in main:
    fail("主路由仍暴露成员管理")
if "MemberManagementPage" in pages:
    fail("新页面仍包含成员管理")
for token in (
    "edit-home-image-",
    "edit-avatar-",
    "edit-market-form-image",
    "edit-reward-list-",
    "edit-reward-detail-",
    "edit-inventory-list-",
    "edit-inventory-detail-",
):
    if token not in pages:
        fail(f"缺少图片编辑覆盖: {token}")

widgets_path = APP / "lib/src/widgets_v2.dart"
widgets = widgets_path.read_text(encoding="utf-8") if widgets_path.exists() else ""
for token in ("BackdropFilter", "GlassSurface", "RainbowFloatingButton", "EditableImage"):
    if token not in widgets:
        fail(f"液态玻璃组件缺少 {token}")

required = {
    "app/lib/src/design.dart",
    "app/lib/src/dual_mode.dart",
    "app/lib/src/media.dart",
    "app/lib/src/pages_v2.dart",
    "app/lib/src/settings_pages_v3.dart",
    "app/lib/src/widgets_v2.dart",
    "app/lib/src/webdav.dart",
    "app/test/app_widget_test.dart",
    "app/test/layout_collision_test.dart",
    "app/test/visual_review_test.dart",
    "app/integration_test/app_flow_test.dart",
    "app/tool/bootstrap_android.sh",
    "app/tool/test_tooling.py",
    "app/android/settings.gradle.kts",
    "app/android/gradle/wrapper/gradle-wrapper.properties",
    "app/android/app/build.gradle.kts",
    "app/android/app/src/main/AndroidManifest.xml",
    "FINAL_REPORT.md",
    "VALIDATION_STATUS.md",
    "RELEASE_NOTES.md",
}
for name in sorted(required):
    if not (ROOT / name).exists():
        fail(f"缺少正式交付文件: {name}")

settings_gradle = (APP / "android/settings.gradle.kts").read_text(encoding="utf-8")
wrapper = (APP / "android/gradle/wrapper/gradle-wrapper.properties").read_text(encoding="utf-8")
for expected in (
    'id("com.android.application") version "9.0.1"',
    'id("org.jetbrains.kotlin.android") version "2.3.20"',
):
    if expected not in settings_gradle:
        fail(f"Android Gradle 配置缺少固定版本: {expected}")
if "gradle-9.1.0-bin.zip" not in wrapper:
    fail("Gradle wrapper 不是固定的 9.1.0 bin")

patterns = [
    re.compile(r"ghp_[A-Za-z0-9]{20,}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
]
ignored = {".git", "node_modules", ".dart_tool", "build", ".gradle", ".idea"}
for path in ROOT.rglob("*"):
    if not path.is_file() or any(part in ignored for part in path.parts):
        continue
    if path.stat().st_size > 2_000_000:
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for pattern in patterns:
        if pattern.search(text):
            fail(f"{path.relative_to(ROOT)} 疑似包含私密凭据")

if ERRORS:
    print("STATIC_SOURCE_CHECK=FAIL")
    for item in ERRORS:
        print(f"- {item}")
    sys.exit(1)

print("STATIC_SOURCE_CHECK=PASS")
print(f"dart_files={len(list(APP.rglob('*.dart')))}")
print("visual_pages=11")
print("member_management=REMOVED")
print("editable_images=ENABLED")
print("liquid_glass=ENABLED")
