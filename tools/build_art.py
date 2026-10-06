"""Bake original, deterministic PBR surfaces. No downloaded or game assets."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parents[1] / 'project/mods/ShootingRange/assets'
OUT.mkdir(parents=True, exist_ok=True)
N = 512
rng = np.random.default_rng(61006)
y, x = np.mgrid[:N, :N]

def noise(scale):
    small = rng.integers(0, 256, (scale, scale), dtype=np.uint8)
    return np.array(Image.fromarray(small).resize((N, N), Image.Resampling.BICUBIC)) / 255.0

def save(name, color, height, rough):
    Image.fromarray(np.uint8(np.clip(color, 0, 1)*255)).save(OUT / f'{name}_color.png')
    dx = (np.roll(height, -1, 1)-np.roll(height, 1, 1))*3
    dy = (np.roll(height, -1, 0)-np.roll(height, 1, 0))*3
    normal = np.stack([-dx, dy, np.ones_like(dx)], axis=2)
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    Image.fromarray(np.uint8((normal*.5+.5)*255)).save(OUT / f'{name}_normal.png')
    Image.fromarray(np.uint8(np.clip(rough, 0, 1)*255)).save(OUT / f'{name}_rough.png')

grain = noise(256)
cloud = noise(16)
rust = np.clip((noise(40)*.6+cloud*.4-.65)*7, 0, 1)
scratch = Image.new('L', (N, N))
draw = ImageDraw.Draw(scratch)
for _ in range(460):
    sx, sy = rng.integers(0, N, 2)
    draw.line((int(sx), int(sy), int(sx+rng.integers(-35, 35)), int(sy+rng.integers(3, 60))), fill=int(rng.integers(80, 255)))
scratches = np.array(scratch)/255.
steel = np.array([.22, .255, .26])[None, None, :] + (grain-.5)[:, :, None]*.075
steel = steel*(1-rust[:, :, None]) + np.array([.21, .091, .038])*rust[:, :, None]
steel += scratches[:, :, None]*.15
save('steel', steel, grain*.08+rust*.15+scratches*.045, .5+rust*.42+grain*.06)

chip = np.clip((noise(110)*.35+cloud*.65-.67)*10, 0, 1)
paint = np.array([.55, .55, .49])[None, None, :]*(.88+grain[:, :, None]*.12)
paint = paint*(1-chip[:, :, None])+steel*chip[:, :, None]
paint -= scratches[:, :, None]*.12
save('paint', paint, grain*.012+chip*.035, .79+chip*.12)

fibers = np.sin(x*.52+noise(24)*16)*.03 + np.sin(x*.12+noise(9)*8)*.075
wood = np.array([.31, .235, .155])[None, None, :]+(fibers+(grain-.5)*.05+cloud*.08)[:, :, None]
knots = np.sin(np.sqrt(((x-155)*.8)**2+((y-250)*.14)**2)*.6)*np.exp(-(((x-155)/65)**2+((y-250)/150)**2))*.035
wood += knots[:, :, None]
save('wood', wood, fibers*.55+grain*.045, .86+grain*.1)

paper = np.array([.65, .61, .50])[None, None, :]+((grain-.5)*.045+cloud*.035)[:, :, None]
card = np.array([.36, .285, .19])[None, None, :]+((grain-.5)*.055+cloud*.035)[:, :, None]
save('card', card, grain*.018, .92+grain*.07)

try:
    font = ImageFont.truetype('C:/Windows/Fonts/bahnschrift.ttf', 19)
    tiny = ImageFont.truetype('C:/Windows/Fonts/bahnschrift.ttf', 12)
except OSError:
    font = tiny = ImageFont.load_default()

for kind in ['bullseye', 'silhouette', 'no_shoot']:
    sheet = Image.fromarray(np.uint8(np.clip(paper, 0, 1)*255))
    d = ImageDraw.Draw(sheet)
    ink = (42, 44, 39)
    d.rectangle((20, 20, 491, 491), outline=(108, 98, 75), width=2)
    d.text((34, 30), 'VOSTOK  /  FIELD PRACTICE', fill=ink, font=font)
    d.text((34, 470), '01    PRECISION SERIES                       2026', fill=ink, font=tiny)
    if kind == 'bullseye':
        for radius in range(190, 10, -20):
            d.ellipse((256-radius, 262-radius, 256+radius, 262+radius), outline=ink, width=2)
        d.ellipse((209, 215, 303, 309), fill=ink)
        d.ellipse((244, 250, 268, 274), outline=(189, 140, 59), width=3)
        d.line((55, 262, 457, 262), fill=(117, 106, 84))
        d.line((256, 61, 256, 463), fill=(117, 106, 84))
        for i in range(1, 10):
            d.text((263+i*20, 267), str(10-i), font=tiny, fill=ink)
    else:
        pts = [(102, 449), (102, 189), (173, 153), (183, 95), (220, 75), (292, 75), (329, 95), (339, 153), (410, 189), (410, 449)]
        d.polygon(pts, fill=(88, 83, 66))
        for bounds in [(177, 193, 335, 376), (211, 230, 301, 338), (228, 110, 284, 149)]:
            d.rounded_rectangle(bounds, radius=14, outline=(184, 169, 132), width=3)
        d.text((248, 275), 'A', fill=(207, 188, 148), font=font)
        if kind == 'no_shoot':
            d.line((105, 170, 409, 445), fill=(194, 155, 61), width=35)
            d.line((409, 170, 105, 445), fill=(194, 155, 61), width=35)
            d.rectangle((76, 411, 435, 452), fill=(30, 31, 27))
            d.text((150, 422), 'NO SHOOT', fill=(228, 196, 96), font=font)
    # Scuffed ink, creases and abrasions, with no pre-existing scored holes.
    for _ in range(330):
        sx, sy = map(int, rng.integers(24, 488, 2))
        d.line((sx, sy, sx+int(rng.integers(2, 9)), sy+1), fill=tuple(map(int, paper[sy, sx]*255)))
    d.line((27, 397, 483, 391), fill=(186, 170, 136), width=1)
    sheet.save(OUT / f'{kind}.png')

hole = Image.new('RGBA', (64, 64))
d = ImageDraw.Draw(hole)
d.ellipse((6, 6, 58, 58), fill=(91, 75, 45, 120))
angles = np.arange(0, 2*np.pi, 2*np.pi/16)
radii = rng.uniform(10, 20, 16)
pts = [(int(32+np.cos(a)*r), int(32+np.sin(a)*r)) for a, r in zip(angles, radii)]
d.polygon(pts, fill=(21, 23, 20, 255))
d.ellipse((24, 24, 40, 40), fill=(9, 11, 10, 255))
hole.save(OUT / 'impact.png')

names=['bullseye','silhouette','no_shoot','torso','gong','square','diamond','rack','tree','wall','doorway','window']
for kind in names:
    icon=Image.new('RGBA',(256,256))
    d=ImageDraw.Draw(icon)
    frame=(80,86,79,255); paint=(192,190,164,255); timber=(126,96,60,255)
    d.line((55,220,55,47),fill=frame,width=9)
    d.line((201,220,201,47),fill=frame,width=9)
    d.line((41,220,73,220),fill=frame,width=7)
    d.line((185,220,217,220),fill=frame,width=7)
    if kind in ['bullseye','silhouette','no_shoot']:
        d.rectangle((60,56,196,192),fill=timber)
        sheet=Image.open(OUT/('silhouette.png' if kind=='silhouette' else kind+'.png')).resize((126,126))
        icon.paste(sheet,(65,61))
    elif kind in ['wall','doorway','window']:
        d.rectangle((47,45,209,222),fill=timber,outline=frame,width=6)
        if kind=='doorway':d.rectangle((95,93,161,223),fill=(0,0,0,0),outline=frame,width=5)
        if kind=='window':d.rectangle((79,96,177,158),fill=(0,0,0,0),outline=frame,width=5)
        for pos in [64,192]:d.line((pos,45,pos,220),fill=(154,124,84),width=3)
    elif kind=='tree':
        d.line((128,220,128,43),fill=frame,width=11)
        for i in range(6):
            sx=86 if i%2==0 else 172;sy=63+i*24
            d.line((128,sy,sx,sy),fill=frame,width=5)
            d.ellipse((sx-12,sy-12,sx+12,sy+12),fill=paint,outline=frame,width=2)
    elif kind=='rack':
        d.line((49,157,207,157),fill=frame,width=10)
        for i in range(5):
            sx=68+i*30
            d.ellipse((sx-11,126,sx+11,148),fill=paint,outline=frame,width=2)
    else:
        d.line((50,47,206,47),fill=frame,width=8)
        for sx in [108,148]:d.line((sx,48,sx,103),fill=frame,width=3)
        if kind=='gong':d.ellipse((86,103,170,187),fill=paint,outline=frame,width=3)
        elif kind=='diamond':d.polygon([(128,100),(172,144),(128,188),(84,144)],fill=paint,outline=frame,width=3)
        elif kind=='torso':d.polygon([(88,195),(168,195),(168,130),(147,112),(144,92),(112,92),(109,112),(88,130)],fill=paint,outline=frame,width=3)
        else:d.rectangle((91,109,165,183),fill=paint,outline=frame,width=3)
    icon.save(OUT/f'icon_{kind}.png')
print(f'Baked {len(list(OUT.glob("*.png")))} original surface maps')
