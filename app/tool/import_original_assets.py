#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
import shutil
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
REPO = APP.parent
MINI = REPO / "miniprogram"
OUT = APP / "assets/original"
OUT.mkdir(parents=True, exist_ok=True)
for old in OUT.iterdir():
    if old.is_file():
        old.unlink()

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp"}
EXCLUDED_PARTS = {
    ".git",
    "node_modules",
    "miniprogram_npm",
    "weui-miniprogram",
}


def first_party(path: Path) -> bool:
    lowered = {part.lower() for part in path.parts}
    return not lowered.intersection(EXCLUDED_PARTS)


def normalize_reference(source: Path, value: str) -> str | None:
    clean = value.strip().split("?", 1)[0].split("#", 1)[0]
    if not clean or clean.startswith(("http://", "https://", "cloud://", "data:")):
        return None
    try:
        if clean.startswith("/"):
            candidate = MINI / clean.lstrip("/")
        else:
            candidate = source.parent / clean
        candidate = candidate.resolve()
        return candidate.relative_to(MINI.resolve()).as_posix()
    except (OSError, ValueError):
        return None


source_by_rel: dict[str, Path] = {}
if MINI.is_dir():
    for source in sorted(MINI.rglob("*")):
        if (
            source.is_file()
            and source.suffix.lower() in IMAGE_EXTENSIONS
            and first_party(source.relative_to(MINI))
        ):
            source_by_rel[source.relative_to(MINI).as_posix()] = source

app_data: dict[str, object] = {}
app_json = MINI / "app.json"
if app_json.exists():
    try:
        app_data = json.loads(app_json.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        app_data = {}

tab_paths: list[str] = []
normal_refs: list[str] = []
selected_refs: list[str] = []
labels: list[str] = []
for item in (app_data.get("tabBar", {}) or {}).get("list", []):
    if not isinstance(item, dict):
        continue
    normal = str(item.get("iconPath", "")).lstrip("/")
    selected = str(item.get("selectedIconPath", "")).lstrip("/")
    if normal:
        normal_refs.append(normal)
        tab_paths.append(normal)
    if selected:
        selected_refs.append(selected)
        tab_paths.append(selected)
    text = str(item.get("text", "")).strip()
    if text:
        labels.append(text)

reference_pattern = re.compile(
    r'''(?:["']([^"']+\.(?:png|jpe?g|gif|webp)(?:\?[^"']*)?)["']|url\(\s*["']?([^)'"\s]+\.(?:png|jpe?g|gif|webp)(?:\?[^)'"\s]*)?)["']?\s*\))''',
    re.I,
)
selected_order: list[str] = []
home_order: list[str] = []
if MINI.is_dir():
    source_files = [
        path
        for path in MINI.rglob("*")
        if path.is_file()
        and path.suffix.lower() in {".wxml", ".wxss", ".js", ".json"}
        and first_party(path.relative_to(MINI))
    ]
    for source in sorted(source_files):
        try:
            text = source.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for match in reference_pattern.finditer(text):
            raw = match.group(1) or match.group(2) or ""
            rel = normalize_reference(source, raw)
            if rel in source_by_rel and rel not in selected_order:
                selected_order.append(rel)
            if (
                rel in source_by_rel
                and "pages/MainPage" in source.as_posix()
                and rel not in home_order
            ):
                home_order.append(rel)

for rel in tab_paths:
    if rel in source_by_rel and rel not in selected_order:
        selected_order.append(rel)

# 某些旧页面通过字符串拼接引用资源；没有直接命中时，仅选择少量一方图片作为回退。
if not selected_order:
    fallback = [
        rel
        for rel in source_by_rel
        if "tabbar" not in rel.lower()
    ][:8]
    selected_order.extend(fallback)
if not home_order:
    home_order.extend(
        rel
        for rel in selected_order
        if rel not in tab_paths and "tabbar" not in rel.lower()
    )

path_map: dict[str, str] = {}
all_assets: list[str] = []
for rel in selected_order:
    source = source_by_rel.get(rel)
    if source is None:
        continue
    safe = re.sub(r"[^A-Za-z0-9._-]", "_", rel.replace("/", "__"))
    # 极少数清洗后重名的资源增加短哈希，避免静默覆盖。
    target = OUT / safe
    if target.exists():
        digest = hashlib.sha1(rel.encode("utf-8")).hexdigest()[:8]
        target = OUT / f"{target.stem}_{digest}{target.suffix}"
    shutil.copy2(source, target)
    asset = f"assets/original/{target.name}"
    path_map[rel] = asset
    path_map[f"/{rel}"] = asset
    all_assets.append(asset)

if not all_assets:
    placeholder = OUT / "placeholder.png"
    placeholder.write_bytes(
        bytes.fromhex(
            "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489"
            "0000000d4944415408d763f8cfc0f01f00050001ff89993d1d0000000049454e44ae426082"
        )
    )
    all_assets.append("assets/original/placeholder.png")

normal = [path_map.get(rel, "") for rel in normal_refs]
selected = [path_map.get(rel, "") for rel in selected_refs]
home = [path_map[rel] for rel in home_order if rel in path_map][:5]
if not home:
    home = [asset for asset in all_assets if asset not in normal + selected][:5]
if not home:
    home = all_assets[:1]
labels = labels or ["首页", "任务", "商城", "仓库"]

page_titles: dict[str, str] = {}
if MINI.is_dir():
    for page_json in MINI.glob("pages/**/index.json"):
        try:
            value = json.loads(page_json.read_text(encoding="utf-8")).get(
                "navigationBarTitleText"
            )
            if value:
                page_titles[page_json.parent.name] = str(value)
        except (OSError, json.JSONDecodeError):
            pass


def dart_list(values: list[str]) -> str:
    return "<String>[\n" + "".join(
        f"    {json.dumps(value, ensure_ascii=False)},\n"
        for value in values
        if value
    ) + "  ]"


def dart_map(values: dict[str, str]) -> str:
    return "<String, String>{\n" + "".join(
        f"    {json.dumps(key, ensure_ascii=False)}: {json.dumps(value, ensure_ascii=False)},\n"
        for key, value in sorted(values.items())
    ) + "  }"


content = f'''// GENERATED by tool/import_original_assets.py. Do not edit by hand.
abstract final class OriginalAssets {{
  static const List<String> all = {dart_list(all_assets)};
  static const List<String> homeImages = {dart_list(home)};
  static const List<String> tabNormal = {dart_list(normal)};
  static const List<String> tabSelected = {dart_list(selected)};
  static const List<String> tabLabels = {dart_list(labels)};
  static const Map<String, String> pageTitles = {dart_map(page_titles)};

  static String? homeAt(int index) =>
      homeImages.isEmpty ? null : homeImages[index % homeImages.length];
  static String? normalTabAt(int index) =>
      index < tabNormal.length ? tabNormal[index] : null;
  static String? selectedTabAt(int index) =>
      index < tabSelected.length ? tabSelected[index] : null;
  static String tabLabelAt(int index) => index < tabLabels.length
      ? tabLabels[index]
      : <String>['首页', '任务', '商城', '仓库'][index];
  static String pageTitle(String page, String fallback) =>
      pageTitles[page] ?? fallback;
}}
'''
(APP / "lib/generated/original_assets.dart").write_text(content, encoding="utf-8")
print(
    f"imported={len(all_assets)} home={len(home)} normal_tabs={len([x for x in normal if x])} labels={labels}"
)
