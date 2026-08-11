#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
APP = Path(__file__).resolve().parents[1]
folder = APP / 'visual_review/emulator'
files = sorted(folder.glob('*.png'))
if not files:
    raise SystemExit('no emulator screenshots')
width=250; gap=20; cols=3
opened=[]
for p in files:
    im=Image.open(p).convert('RGB')
    r=width/im.width
    opened.append((p, im.resize((width, round(im.height*r)))))
cap=34; cell=max(im.height for _,im in opened)+cap
rows=(len(opened)+cols-1)//cols
out=Image.new('RGB',(gap+cols*(width+gap),gap+rows*(cell+gap)),'white')
d=ImageDraw.Draw(out); f=ImageFont.load_default()
for i,(p,im) in enumerate(opened):
    x=gap+(i%cols)*(width+gap); y=gap+(i//cols)*(cell+gap)
    d.text((x,y+8),p.stem,fill='black',font=f); out.paste(im,(x,y+cap))
out.save(folder/'emulator-contact-sheet.png')
