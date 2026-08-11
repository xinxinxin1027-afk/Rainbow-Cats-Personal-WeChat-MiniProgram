#!/usr/bin/env python3
from __future__ import annotations

import collections
import json
import re
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
REPO = APP.parent
CANDIDATES = [REPO / "miniprogram"]
MINI = next((p for p in CANDIDATES if p.is_dir()), None)

fallback = {
    "primary": "#FF99AA",
    "background": "#F6F6F6",
    "text": "#333333",
    "radius": 14.0,
    "title": "Rainbow Cats",
}
app = {}
if MINI and (MINI / "app.json").exists():
    try:
        app = json.loads((MINI / "app.json").read_text(encoding="utf-8"))
    except Exception:
        app = {}
window = app.get("window", {}) if isinstance(app, dict) else {}
tab = app.get("tabBar", {}) if isinstance(app, dict) else {}

hex_re = re.compile(r"#[0-9a-fA-F]{6}")
colors: collections.Counter[str] = collections.Counter()
radii: collections.Counter[float] = collections.Counter()
if MINI:
    excluded = {'.git', 'node_modules', 'miniprogram_npm', 'weui-miniprogram'}
    for file in MINI.rglob("*.wxss"):
        if {part.lower() for part in file.relative_to(MINI).parts}.intersection(excluded):
            continue
        text = file.read_text(encoding="utf-8", errors="ignore")
        colors.update(value.upper() for value in hex_re.findall(text))
        for number, unit in re.findall(r"border-radius\s*:\s*([0-9.]+)(rpx|px)", text, re.I):
            value = float(number) / (2 if unit.lower() == "rpx" else 1)
            if 5 <= value <= 30:
                radii[value] += 1

def valid(value, default):
    return value.upper() if isinstance(value, str) and hex_re.fullmatch(value) else default

primary = valid(tab.get("selectedColor"), valid(window.get("navigationBarBackgroundColor"), fallback["primary"]))
if primary in {"#FFFFFF", "#000000"}:
    pinks = [c for c, _ in colors.most_common() if int(c[1:3], 16) > 180 and int(c[3:5], 16) < 210 and int(c[5:7], 16) < 225]
    primary = pinks[0] if pinks else fallback["primary"]
background = valid(window.get("backgroundColor"), fallback["background"])
if background == "#FFFFFF":
    near_white = [c for c, _ in colors.most_common() if min(int(c[i:i+2], 16) for i in (1,3,5)) > 235 and c != "#FFFFFF"]
    background = near_white[0] if near_white else fallback["background"]
text = valid(tab.get("color"), fallback["text"])
radius = radii.most_common(1)[0][0] if radii else fallback["radius"]
title = str(window.get("navigationBarTitleText") or fallback["title"]).replace("'", "\\'")

def argb(value: str) -> str:
    return "0xFF" + value[1:].upper()

def darken(value: str, factor: float = .86) -> str:
    rgb = [max(0, min(255, round(int(value[i:i+2], 16) * factor))) for i in (1,3,5)]
    return "#" + "".join(f"{v:02X}" for v in rgb)

content = f'''import 'package:flutter/material.dart';

// GENERATED from the original app.json and WXSS.
abstract final class OriginalStyle {{
  static const Color primary = Color({argb(primary)});
  static const Color primaryDark = Color({argb(darken(primary))});
  static const Color background = Color({argb(background)});
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color({argb(text)});
  static const Color muted = Color(0xFF8E8E93);
  static const Color divider = Color(0xFFF0DDE1);
  static const double cardRadius = {radius:.1f};
  static const String appTitle = '{title}';
}}
'''
(APP / "lib/generated/original_style.dart").write_text(content, encoding="utf-8")
print(f"primary={primary} background={background} radius={radius}")
