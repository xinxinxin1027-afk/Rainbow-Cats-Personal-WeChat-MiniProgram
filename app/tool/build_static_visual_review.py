#!/usr/bin/env python3
from __future__ import annotations

import html
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

APP = Path(__file__).resolve().parents[1]
GOLDENS = APP / "visual_review/goldens"
OUT = APP / "visual_review"
OUT.mkdir(parents=True, exist_ok=True)
files = sorted(GOLDENS.glob("*.png"))
if not files:
    raise SystemExit("没有找到视觉基线 PNG，请先运行 flutter test --update-goldens test/visual_review_test.dart")

thumb_w = 270
padding = 24
caption_h = 42
columns = 3
opened = []
for path in files:
    image = Image.open(path).convert("RGB")
    ratio = thumb_w / image.width
    opened.append((path, image.resize((thumb_w, round(image.height * ratio)))))
cell_h = max(img.height for _, img in opened) + caption_h
rows = (len(opened) + columns - 1) // columns
sheet = Image.new("RGB", (padding + columns * (thumb_w + padding), padding + rows * (cell_h + padding)), "white")
draw = ImageDraw.Draw(sheet)
font = ImageFont.load_default()
for index, (path, image) in enumerate(opened):
    col = index % columns
    row = index // columns
    x = padding + col * (thumb_w + padding)
    y = padding + row * (cell_h + padding)
    sheet.paste(image, (x, y + caption_h))
    draw.text((x, y + 10), path.stem, fill="black", font=font)
    draw.rectangle((x, y + caption_h, x + image.width - 1, y + caption_h + image.height - 1), outline="#dddddd")
sheet_path = OUT / "visual-review-contact-sheet.png"
sheet.save(sheet_path, quality=92)

cards = "\n".join(
    f'<figure><img src="goldens/{html.escape(path.name)}" alt="{html.escape(path.stem)}"><figcaption>{html.escape(path.stem)}</figcaption></figure>'
    for path in files
)
html_doc = f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rainbow Cats Android 视觉复检</title><style>
body{{font-family:system-ui,-apple-system,"PingFang SC",sans-serif;margin:0;background:#f7f7f7;color:#222}}header{{padding:28px;background:white;position:sticky;top:0;z-index:2;box-shadow:0 2px 12px #0001}}main{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:24px;padding:24px;align-items:start}}figure{{margin:0;background:white;padding:14px;border-radius:16px;box-shadow:0 4px 20px #0001}}img{{display:block;width:100%;height:auto;border:1px solid #eee}}figcaption{{font-weight:700;padding:12px 2px 2px}}code{{background:#f0f0f0;padding:2px 5px;border-radius:4px}}</style></head><body><header><h1>Rainbow Cats Android 视觉复检</h1><p>固定视口 393×852；共 {len(files)} 个页面。截图由 Flutter Widget Golden 渲染生成。</p></header><main>{cards}</main></body></html>'''
(OUT / "index.html").write_text(html_doc, encoding="utf-8")
print(sheet_path)
