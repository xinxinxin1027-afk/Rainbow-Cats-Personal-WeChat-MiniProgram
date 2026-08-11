#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageOps, ImageStat

APP = Path(__file__).resolve().parents[1]
ROOT = APP.parent
ORIGINAL = ROOT / "Pics"
EMULATOR = APP / "visual_review" / "emulator"
OUTPUT = APP / "visual_review" / "comparison"
OUTPUT.mkdir(parents=True, exist_ok=True)

PAGE_MAP = [
    ("Main", ("main", "home", "首页")),
    ("Mission", ("mission", "任务")),
    ("MissionAdd", ("missionadd", "mission_add", "add-mission", "发布任务")),
    ("MissionDetail", ("missiondetail", "mission_detail", "任务详情")),
    ("Market", ("market", "商城")),
    ("MarketAdd", ("marketadd", "market_add", "上架商品")),
    ("MarketDetail", ("marketdetail", "market_detail", "商品详情")),
    ("Account", ("account", "仓库")),
    ("ItemDetail", ("itemdetail", "item_detail", "物品详情")),
]


def image_files(folder: Path) -> list[Path]:
    if not folder.exists():
        return []
    return sorted(
        p for p in folder.rglob("*")
        if p.is_file() and p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    )


def find_original(stem: str) -> Path | None:
    for suffix in (".jpg", ".png", ".jpeg", ".webp"):
        candidate = ORIGINAL / f"{stem}{suffix}"
        if candidate.exists():
            return candidate
    return None


def find_emulator(tokens: tuple[str, ...], images: list[Path]) -> Path | None:
    lowered = [(p, p.stem.lower().replace("-", "").replace("_", "")) for p in images]
    normalized = [t.lower().replace("-", "").replace("_", "") for t in tokens]
    for token in normalized:
        for path, stem in lowered:
            if token and token in stem:
                return path
    return None


def fit(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    return ImageOps.contain(image.convert("RGB"), box, Image.Resampling.LANCZOS)


def mean_rgb_difference(left: Image.Image, right: Image.Image) -> float:
    size = (360, 720)
    a = ImageOps.fit(left.convert("RGB"), size, Image.Resampling.LANCZOS)
    b = ImageOps.fit(right.convert("RGB"), size, Image.Resampling.LANCZOS)
    stat = ImageStat.Stat(ImageChops.difference(a, b))
    return round(sum(stat.mean) / 3.0, 2)


emulator_images = image_files(EMULATOR)
records: list[dict[str, object]] = []
rows: list[tuple[str, Path, Path]] = []
for original_stem, tokens in PAGE_MAP:
    original = find_original(original_stem)
    emulator = find_emulator(tokens, emulator_images)
    if original and emulator:
        with Image.open(original) as left, Image.open(emulator) as right:
            metric = mean_rgb_difference(left, right)
            records.append({
                "page": original_stem,
                "original": str(original.relative_to(ROOT)),
                "emulator": str(emulator.relative_to(ROOT)),
                "mean_rgb_difference": metric,
                "note": "仅用于辅助发现明显视觉偏差；设备比例和系统栏会影响该数值。",
            })
        rows.append((original_stem, original, emulator))

if not rows:
    records.append({
        "matched_pages": 0,
        "original_count": len(image_files(ORIGINAL)),
        "emulator_count": len(emulator_images),
        "note": "未按文件名匹配到同页截图；Emulator 截图仍保存在 visual_review/emulator。",
    })
else:
    width = 820
    image_box = (360, 720)
    row_height = 770
    canvas = Image.new("RGB", (width, row_height * len(rows)), "white")
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()
    for index, (name, original, emulator) in enumerate(rows):
        y = index * row_height
        draw.text((16, y + 8), f"{name}: original", fill="black", font=font)
        draw.text((420, y + 8), f"{name}: emulator", fill="black", font=font)
        with Image.open(original) as left, Image.open(emulator) as right:
            left_fit = fit(left, image_box)
            right_fit = fit(right, image_box)
            canvas.paste(left_fit, (16 + (360 - left_fit.width) // 2, y + 38))
            canvas.paste(right_fit, (420 + (360 - right_fit.width) // 2, y + 38))
    canvas.save(OUTPUT / "original-vs-emulator.png", quality=92)

(OUTPUT / "metrics.json").write_text(
    json.dumps(records, ensure_ascii=False, indent=2),
    encoding="utf-8",
)
print(json.dumps({"matched": len(rows), "emulator_images": len(emulator_images)}, ensure_ascii=False))
