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


def balanced_dart(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    stack: list[tuple[str, int, int]] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    line = 1
    column = 0
    index = 0
    state = "code"
    quote = ""
    triple = False
    while index < len(text):
        char = text[index]
        nxt = text[index + 1] if index + 1 < len(text) else ""
        third = text[index : index + 3]
        if char == "\n":
            line += 1
            column = 0
        else:
            column += 1

        if state == "line_comment":
            if char == "\n":
                state = "code"
            index += 1
            continue
        if state == "block_comment":
            if char == "*" and nxt == "/":
                state = "code"
                index += 2
                column += 1
            else:
                index += 1
            continue
        if state == "string":
            if char == "\\":
                index += 2
                column += 1
                continue
            if triple and third == quote * 3:
                state = "code"
                index += 3
                column += 2
                continue
            if not triple and char == quote:
                state = "code"
            index += 1
            continue

        if char == "/" and nxt == "/":
            state = "line_comment"
            index += 2
            column += 1
            continue
        if char == "/" and nxt == "*":
            state = "block_comment"
            index += 2
            column += 1
            continue
        if char in {"'", '"'}:
            quote = char
            triple = third == char * 3
            state = "string"
            index += 3 if triple else 1
            if triple:
                column += 2
            continue
        if char in "([{":
            stack.append((char, line, column))
        elif char in ")]}":
            if not stack or stack[-1][0] != pairs[char]:
                fail(f"{path.relative_to(ROOT)}:{line}:{column} 括号不匹配 {char}")
                return
            stack.pop()
        index += 1
    if state in {"block_comment", "string"}:
        fail(f"{path.relative_to(ROOT)} 文件结尾仍在 {state}")
    if stack:
        fail(f"{path.relative_to(ROOT)} 未闭合括号 {stack[-1]}")


def check_imports(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for target in re.findall(r"^import\s+['\"]([^'\"]+)['\"]", text, re.M):
        if target.startswith(("dart:", "package:")):
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.exists():
            fail(f"{path.relative_to(ROOT)} 导入不存在: {target}")


for dart in sorted(APP.rglob("*.dart")):
    balanced_dart(dart)
    check_imports(dart)
    text = dart.read_text(encoding="utf-8")
    for forbidden in ("UnimplementedError", "throw UnsupportedError", "敬请期待", "开发中"):
        if forbidden in text:
            fail(f"{dart.relative_to(ROOT)} 含未完成功能标记: {forbidden}")

pages = (APP / "lib/src/pages.dart").read_text(encoding="utf-8")
page_names_match = re.search(
    r"pageNames\s*=\s*<String>\[(.*?)\];", pages, re.S
)
if not page_names_match:
    fail("无法读取视觉页面名称")
else:
    page_count = len(re.findall(r"'[^']+'", page_names_match.group(1)))
    if page_count != 12:
        fail(f"视觉页面名称应为 12 个，实际 {page_count}")

required = {
    "app/lib/src/webdav.dart",
    "app/lib/src/settings_pages.dart",
    "app/test/webdav_test.dart",
    "app/test/app_widget_test.dart",
    "app/integration_test/app_flow_test.dart",
    "app/tool/bootstrap_android.sh",
    "app/tool/test_tooling.py",
    "app/android/settings.gradle.kts",
    "app/android/build.gradle.kts",
    "app/android/gradle.properties",
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
wrapper_properties = (
    APP / "android/gradle/wrapper/gradle-wrapper.properties"
).read_text(encoding="utf-8")
for expected in (
    'id("com.android.application") version "9.0.1"',
    'id("org.jetbrains.kotlin.android") version "2.3.20"',
):
    if expected not in settings_gradle:
        fail(f"Android Gradle 配置缺少固定版本: {expected}")
if "gradle-9.1.0-bin.zip" not in wrapper_properties:
    fail("Gradle wrapper 版本不是 9.1.0 binary distribution")
if "downloads.gradle.org/distributions/gradle-9.1.0-bin.zip" not in wrapper_properties:
    fail("Gradle wrapper 未使用官方直连下载地址")

secret_patterns = [
    re.compile(r"ghp_[A-Za-z0-9]{20,}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
]
IGNORED_SCAN_PARTS = {
    ".git",
    "node_modules",
    ".dart_tool",
    "build",
    ".gradle",
    ".idea",
}
for path in ROOT.rglob("*"):
    if (
        not path.is_file()
        or any(part in IGNORED_SCAN_PARTS for part in path.parts)
        or path.stat().st_size > 2_000_000
    ):
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for pattern in secret_patterns:
        if pattern.search(text):
            fail(f"{path.relative_to(ROOT)} 疑似包含私密凭据")

if ERRORS:
    print("STATIC_SOURCE_CHECK=FAIL")
    for error in ERRORS:
        print(f"- {error}")
    sys.exit(1)
print("STATIC_SOURCE_CHECK=PASS")
print(f"dart_files={len(list(APP.rglob('*.dart')))}")
