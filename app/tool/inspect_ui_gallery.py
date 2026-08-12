#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageStat

APP = Path(__file__).resolve().parents[1]
ROOT = APP / "visual_review"
FILES = sorted((ROOT / "goldens").glob("*.png")) + sorted(
    (ROOT / "interactions").glob("*.png")
)
REPORT = ROOT / "UI_VISUAL_RECOGNITION.txt"

errors: list[str] = []
rows: list[str] = []

if len(FILES) < 20:
    errors.append(f"截图数量过少: {len(FILES)}")
if len(FILES) >= 100:
    errors.append(f"截图数量必须小于100: {len(FILES)}")

old_pink = (255, 153, 170)


def near(pixel: tuple[int, int, int], target: tuple[int, int, int], tolerance: int) -> bool:
    return all(abs(pixel[i] - target[i]) <= tolerance for i in range(3))


for path in FILES:
    image = Image.open(path).convert("RGB")
    width, height = image.size
    if width < 300 or height < 500:
        errors.append(f"{path.name}: 尺寸异常 {width}x{height}")

    stat = ImageStat.Stat(image)
    std = sum(stat.stddev) / 3
    if std < 12:
        errors.append(f"{path.name}: 画面变化过少，疑似空白/纯色，std={std:.2f}")

    thumb = image.resize((max(1, width // 8), max(1, height // 8)))
    pixels = list(thumb.getdata())
    nearly_white = sum(1 for p in pixels if min(p) >= 247) / max(1, len(pixels))
    nearly_black = sum(1 for p in pixels if max(p) <= 12) / max(1, len(pixels))
    if nearly_white > 0.94:
        errors.append(f"{path.name}: 白屏比例过高 {nearly_white:.1%}")
    if nearly_black > 0.80:
        errors.append(f"{path.name}: 黑屏比例过高 {nearly_black:.1%}")

    # 专门防止用户截图中那种占满宽度的大块 #FF99AA 小程序式顶栏回归。
    top = image.crop((0, 0, width, min(height, 240))).resize((98, 120))
    top_pixels = top.load()
    consecutive = 0
    max_consecutive = 0
    for y in range(top.height):
        pink_ratio = sum(
            1 for x in range(top.width) if near(top_pixels[x, y], old_pink, 12)
        ) / top.width
        if pink_ratio > 0.82:
            consecutive += 1
            max_consecutive = max(max_consecutive, consecutive)
        else:
            consecutive = 0
    if max_consecutive >= 14:
        errors.append(
            f"{path.name}: 检测到旧式整宽粉色顶栏，连续行={max_consecutive}"
        )

    rows.append(
        f"{path.relative_to(ROOT)}\t{width}x{height}\tstd={std:.2f}\t"
        f"white={nearly_white:.3f}\tblack={nearly_black:.3f}\t"
        f"solid_pink_rows={max_consecutive}"
    )

status = "PASS" if not errors else "FAIL"
lines = [
    f"status={status}",
    f"screenshot_count={len(FILES)}",
    "screenshot_limit_lt_100=PASS" if len(FILES) < 100 else "screenshot_limit_lt_100=FAIL",
    "blank_screen_check=" + ("PASS" if not any("白屏" in e or "黑屏" in e for e in errors) else "FAIL"),
    "old_solid_pink_header_check=" + ("PASS" if not any("粉色顶栏" in e for e in errors) else "FAIL"),
    "",
    "[screenshots]",
    *rows,
]
if errors:
    lines.extend(["", "[errors]", *errors])
REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(REPORT)
print("\n".join(lines[:6]))
if errors:
    raise SystemExit(1)
