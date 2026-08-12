#!/usr/bin/env python3
from __future__ import annotations

import html
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

APP = Path(__file__).resolve().parents[1]
OUT = APP / "visual_review"
OUT.mkdir(parents=True, exist_ok=True)
files = sorted((OUT / "goldens").glob("*.png")) + sorted(
    (OUT / "interactions").glob("*.png")
)
if not files:
    raise SystemExit("没有找到视觉 PNG，请先生成页面与交互截图")
if len(files) >= 100:
    raise SystemExit(f"视觉截图数量必须小于100，实际 {len(files)}")

thumb_w = 250
padding = 20
caption_h = 42
columns = 4
opened = []
for path in files:
    image = Image.open(path).convert("RGB")
    ratio = thumb_w / image.width
    opened.append((path, image.resize((thumb_w, round(image.height * ratio)))))
cell_h = max(img.height for _, img in opened) + caption_h
rows = (len(opened) + columns - 1) // columns
sheet = Image.new(
    "RGB",
    (padding + columns * (thumb_w + padding), padding + rows * (cell_h + padding)),
    "white",
)
draw = ImageDraw.Draw(sheet)
font = ImageFont.load_default()
for index, (path, image) in enumerate(opened):
    col = index % columns
    row = index // columns
    x = padding + col * (thumb_w + padding)
    y = padding + row * (cell_h + padding)
    sheet.paste(image, (x, y + caption_h))
    label = f"{path.parent.name}/{path.stem}"
    draw.text((x, y + 10), label, fill="black", font=font)
    draw.rectangle(
        (x, y + caption_h, x + image.width - 1, y + caption_h + image.height - 1),
        outline="#dddddd",
    )
sheet_path = OUT / "visual-review-contact-sheet.png"
sheet.save(sheet_path, quality=92)

cards = "\n".join(
    f'<figure><img src="{html.escape(path.relative_to(OUT).as_posix())}" '
    f'alt="{html.escape(path.stem)}"><figcaption>{html.escape(path.parent.name)}/{html.escape(path.stem)}</figcaption></figure>'
    for path in files
)
html_doc = f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rainbow Cats UI 视觉复检</title><style>
body{{font-family:system-ui,-apple-system,"PingFang SC",sans-serif;margin:0;background:#faf8f4;color:#2b2926}}header{{padding:28px;background:#ffffffd9;backdrop-filter:blur(20px);position:sticky;top:0;z-index:2;box-shadow:0 8px 28px #00000010}}main{{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px;padding:20px;align-items:start}}figure{{margin:0;background:#ffffffdd;padding:12px;border-radius:24px;box-shadow:0 10px 28px #00000012}}img{{display:block;width:100%;height:auto;border-radius:16px;border:1px solid #fff}}figcaption{{font-weight:700;padding:10px 2px 2px;color:#625f58}}</style></head><body><header><h1>Rainbow Cats UI 视觉复检</h1><p>393×852 主视觉；页面基线 + 实际交互状态共 {len(files)} 张，严格小于 100 张。</p></header><main>{cards}</main></body></html>'''
(OUT / "index.html").write_text(html_doc, encoding="utf-8")
print(sheet_path)
print(f"screenshots={len(files)}")
