#!/usr/bin/env python3
"""Store art for all three apps, drawn from the apps' own illustrations and
real screenshots.

Steps per app:
  1. Renders the app's mascot, icon and illustrations with Flutter
     (apps/<app>/tool/art_test.dart) into build/art/<app>/.
  2. Writes the Play icon, Android launcher icons and iOS app icons.
  3. Frames the phone screenshots from tool/store_shots.sh into Play
     listing screenshots: soft brand gradient, brand row, big headline,
     one-line subhead, two tilted phones, the mascot popping out on some.
  4. Draws the 1024x500 feature graphic in the same style.

Writes:
  store/<app>/icon-512.png
  store/<app>/feature-graphic.png
  store/<app>/listing-screenshots/NN.png   (1080x1920, upload in order)
  apps/<app>/android/app/src/main/res/mipmap-*/ic_launcher.png
  apps/<app>/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png

Run tool/store_shots.sh first. Usage: tool/make_store_art.py [app ...]
"""
import math
import os
import random
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, 'tool', 'fonts')
BLACK = os.path.join(FONTS, 'InterDisplay-Black.otf')
EXTRA = os.path.join(FONTS, 'InterDisplay-ExtraBold.otf')
SEMI = os.path.join(FONTS, 'Inter-SemiBold.otf')
MEDIUM = os.path.join(FONTS, 'Inter-Medium.otf')
MIPMAP = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
W, H = 1080, 1920


def hexc(h, a=255):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


# Light and dark palettes per app, picked from each app's seed, accent and
# gradient-end colours (see apps/<app>/lib/src/app.dart).
APPS = {
    'hours_tracker': dict(
        name='Wagebird',
        tagline='Hours, overtime and pay, worked out for you.',
        brand='#00897B', accent='#FFB300',
        light=('#E3F5F1', '#E2EDFB', '#FFF0CF'), ink='#0D2B30',
        dark=('#0B2B33', '#0A1B3A', '#FFB300'),
        confetti=['#00897B', '#FFB300', '#4FC3F7', '#FF8A65'],
        slides=[
            ('1_week', '2_pay', 'Know your pay before payday.',
             'Clock in with a tap. Overtime works itself out.', False, True),
            ('2_pay', '1_week', 'Overtime, worked out right.',
             'Daily and weekly limits, time and a half, double time.', False, False),
            ('0_welcome', '1_week', 'Meet Wagebird.',
             'A friendly little bird that keeps your hours honest.', False, False),
            ('3_pro', '2_pay', 'Timesheets for payroll.',
             'PDF and CSV exports and more jobs with Pro.', False, True),
            ('4_dark_week', '5_dark_pay', 'Built for night shifts.',
             'A calm dark mode, and overnight shifts that just work.', True, False),
            ('5_dark_pay', '4_dark_week', 'Private by default.',
             'No account. No ads. Your hours stay on your phone.', True, True),
        ],
    ),
    'fuel_log': dict(
        name='Wrenchnote',
        tagline='Real fuel economy, service reminders and every car cost.',
        brand='#3949AB', accent='#FF7043',
        light=('#E7EAFA', '#F1E8F6', '#FFE4D8'), ink='#141A3C',
        dark=('#121838', '#1C1233', '#FF7043'),
        confetti=['#3949AB', '#FF7043', '#26A69A', '#FFCA28'],
        slides=[
            ('1_fuel', '3_costs', 'Real fuel economy. Every tank.',
             "Partial and missed fill-ups won't skew your numbers.", False, True),
            ('2_reminders', '1_fuel', 'Never miss an oil change.',
             'Service reminders by date, distance or both.', False, False),
            ('3_costs', '2_reminders', 'See what your car really costs.',
             'Fuel and service totals, and cost per km or mile.', False, True),
            ('0_welcome', '1_fuel', 'Meet Wrenchnote.',
             "Your car's logbook, with a wrench and a smile.", False, False),
            ('4_dark_fuel', '5_dark_costs', 'Your units, your way.',
             'MPG or L/100 km, miles or kilometres, light or dark.', True, False),
            ('5_dark_costs', '4_dark_fuel', 'No account. No ads.',
             "Your car's history stays on your phone.", True, True),
        ],
    ),
    'home_inventory': dict(
        name='Housetally',
        tagline='Everything you own, ready for an insurance claim.',
        brand='#A1452C', accent='#F2B33D',
        light=('#FBEEE4', '#F4E5EE', '#FFF0C8'), ink='#3A1821',
        dark=('#2B1418', '#22111F', '#F2B33D'),
        confetti=['#A1452C', '#F2B33D', '#8E5A9B', '#3F8F7A'],
        slides=[
            ('1_rooms', '2_warranties', 'Everything you own, tallied.',
             "Room by room, with photos and what it's worth.", False, True),
            ('3_item', '1_rooms', 'Snap it. Price it. Done.',
             'Photos, receipt, serial number and warranty together.', False, False),
            ('2_warranties', '3_item', 'Warranties, counted down.',
             "See what's ending soon while you can still claim.", False, True),
            ('6_pro', '1_rooms', 'Claim-ready in one tap.',
             'A PDF report with every photo and receipt, room by room.', False, False),
            ('0_welcome', '1_rooms', 'Meet Housetally.',
             "A little house that keeps count, so you don't have to.", False, False),
            ('4_dark_rooms', '5_dark_warranties', 'Easy on the eyes.',
             'A warm dark mode for late-night counting.', True, False),
            ('5_dark_warranties', '4_dark_rooms', 'Private by default.',
             'No account. Nothing uploaded. Your list stays on your phone.', True, True),
        ],
    ),
}


def font(path, size):
    return ImageFont.truetype(path, size)


def render_art(app):
    out = os.path.join(ROOT, 'build', 'art', app)
    env = dict(os.environ, PATH='/opt/flutter/bin:' + os.environ.get('PATH', ''))
    subprocess.run(['flutter', 'test', 'tool/art_test.dart', f'--dart-define=ART_OUT={out}'],
                   cwd=os.path.join(ROOT, 'apps', app), env=env, check=True, stdout=subprocess.DEVNULL)
    return {n: Image.open(os.path.join(out, n + '.png')).convert('RGBA')
            for n in ('icon', 'mascot', 'mascot_dark', 'hero', 'pro')}


def gradient(size, c1, c2, blob):
    """Diagonal two-colour wash with a soft glow of a third colour top right."""
    w, h = size
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    t = np.clip((x / w * 0.35 + y / h * 0.65), 0, 1)[..., None]
    a = np.array(hexc(c1)[:3], np.float32)
    b = np.array(hexc(c2)[:3], np.float32)
    img = a * (1 - t) + b * t
    d = np.sqrt((x - w * 0.85) ** 2 + (y - h * 0.12) ** 2) / (max(w, h) * 0.55)
    g = np.clip(1 - d, 0, 1)[..., None] ** 2 * 0.75
    img = img * (1 - g) + np.array(hexc(blob)[:3], np.float32) * g
    return Image.fromarray(img.astype(np.uint8), 'RGB').convert('RGBA')


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), radius=radius, fill=255)
    out = img.copy()
    out.putalpha(Image.composite(img.getchannel('A'), mask, mask) if img.mode == 'RGBA' else mask)
    return out


def star(d, cx, cy, r, fill):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=fill)


def decor(size, colors, seed, dark):
    """Floating confetti on light slides, glowing dots on dark ones; kept to
    the edges so they never sit behind the headline."""
    w, h = size
    layer = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rnd = random.Random(seed)
    for i in range(22 if not dark else 30):
        x = rnd.choice([rnd.uniform(0, w * 0.12), rnd.uniform(w * 0.88, w), rnd.uniform(0, w)])
        y = rnd.uniform(h * 0.02, h * 0.98)
        if w * 0.08 < x < w * 0.92 and h * 0.04 < y < h * 0.28:
            continue
        s = rnd.uniform(w * 0.008, w * 0.02)
        if dark:
            c = hexc(colors[1] if i % 3 else colors[2])
            glow = Image.new('RGBA', size, (0, 0, 0, 0))
            ImageDraw.Draw(glow).ellipse((x - s * 2.2, y - s * 2.2, x + s * 2.2, y + s * 2.2), fill=c[:3] + (70,))
            layer.alpha_composite(glow.filter(ImageFilter.GaussianBlur(s)))
            d.ellipse((x - s * 0.5, y - s * 0.5, x + s * 0.5, y + s * 0.5), fill=c[:3] + (230,))
            continue
        c = hexc(rnd.choice(colors), 95)
        kind = i % 3
        if kind == 0:
            star(d, x, y, s, c)
        elif kind == 1:
            d.ellipse((x - s * 0.6, y - s * 0.6, x + s * 0.6, y + s * 0.6), fill=c)
        else:
            piece = Image.new('RGBA', (int(s * 2.4), int(s * 1.1)), (0, 0, 0, 0))
            ImageDraw.Draw(piece).rounded_rectangle((0, 0, piece.size[0] - 1, piece.size[1] - 1),
                                                    radius=int(s * 0.3), fill=c)
            piece = piece.rotate(rnd.uniform(0, 180), expand=True, resample=Image.BICUBIC)
            layer.alpha_composite(piece, (int(x), int(y)))
    return layer


def phone(shot, width):
    """A phone with a punch-hole camera and status bar around [shot]."""
    shot = shot.convert('RGB')
    sw = width
    sh = round(sw * shot.size[1] / shot.size[0])
    bar = round(sw * 0.075)
    screen = Image.new('RGBA', (sw, sh + bar), shot.getpixel((shot.size[0] // 2, 2)) + (255,))
    screen.paste(shot.resize((sw, sh), Image.LANCZOS), (0, bar))
    top = shot.getpixel((shot.size[0] // 2, 2))
    ink = (20, 20, 24, 255) if sum(top) > 380 else (245, 245, 245, 255)
    d = ImageDraw.Draw(screen)
    d.text((round(sw * 0.07), round(bar * 0.52)), '9:41', font=font(SEMI, round(bar * 0.42)), fill=ink, anchor='lm')
    bx, by = sw - round(sw * 0.07), round(bar * 0.52)
    u = bar * 0.16
    d.rounded_rectangle((bx - u * 2.6, by - u, bx, by + u), radius=u * 0.4, fill=ink)       # battery
    for k in range(4):                                                                        # signal
        x = bx - u * 4.4 + k * u * 0.55 - u * 2.2
        d.rectangle((x, by + u - (k + 1) * u * 0.5, x + u * 0.35, by + u), fill=ink)
    screen = rounded(screen, round(sw * 0.085))
    bezel = round(sw * 0.032)
    fw, fh = sw + bezel * 2, screen.size[1] + bezel * 2
    frame = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((0, 0, fw - 1, fh - 1), radius=round(sw * 0.115), fill=(24, 24, 28, 255))
    fd.rounded_rectangle((2, 2, fw - 3, fh - 3), radius=round(sw * 0.112), outline=(70, 70, 78, 255), width=3)
    frame.alpha_composite(screen, (bezel, bezel))
    cam = sw * 0.024
    fd.ellipse((fw / 2 - cam, bezel + bar / 2 - cam, fw / 2 + cam, bezel + bar / 2 + cam), fill=(8, 8, 10, 255))
    return frame


def place(canvas, img, xy, angle, shadow=True):
    rot = img.rotate(angle, expand=True, resample=Image.BICUBIC)
    x, y = xy
    if shadow:
        sh = Image.new('RGBA', rot.size, (0, 0, 0, 0))
        sh.putalpha(rot.getchannel('A').point(lambda a: int(a * 0.32)))
        sh = sh.filter(ImageFilter.GaussianBlur(28))
        canvas.alpha_composite(sh, (int(x + 18), int(y + 34)))
    canvas.alpha_composite(rot, (int(x), int(y)))


def wrap(text, f, max_w, draw):
    words, lines, cur = text.split(), [], ''
    for wd in words:
        t = (cur + ' ' + wd).strip()
        if draw.textlength(t, font=f) <= max_w:
            cur = t
        else:
            lines.append(cur)
            cur = wd
    lines.append(cur)
    return lines


def brand_row(canvas, icon, name, color, x, y, size):
    canvas.alpha_composite(rounded(icon.resize((size, size), Image.LANCZOS), round(size * 0.24)), (x, y))
    ImageDraw.Draw(canvas).text((x + size + round(size * 0.28), y + size / 2), name, font=font(EXTRA, round(size * 0.58)),
                                fill=hexc(color), anchor='lm')


def slide(cfg, art, shots_dir, spec, index):
    front_n, back_n, headline, sub, dark, mascot = spec
    if dark:
        c1, c2, glow = cfg['dark']
        canvas = gradient((W, H), c1, c2, c1)
        ink, soft, brand_c = (255, 255, 255, 255), (255, 255, 255, 190), '#FFFFFF'
        canvas.alpha_composite(decor((W, H), [cfg['brand'], glow, '#FFFFFF'], index, True))
    else:
        c1, c2, blob = cfg['light']
        canvas = gradient((W, H), c1, c2, blob)
        ink, soft, brand_c = hexc(cfg['ink']), hexc(cfg['ink'], 165), cfg['brand']
        canvas.alpha_composite(decor((W, H), cfg['confetti'], index, False))
    brand_row(canvas, art['icon'], cfg['name'], brand_c, 76, 92, 76)
    d = ImageDraw.Draw(canvas)
    size = 112
    while True:
        hf = font(BLACK, size)
        lines = wrap(headline, hf, W - 152, d)
        if len(lines) <= 2 or size <= 80:
            break
        size -= 4
    y = 222
    for ln in lines:
        d.text((76, y), ln, font=hf, fill=ink)
        y += round(size * 1.08)
    sf = font(MEDIUM, 42)
    y += 18
    for ln in wrap(sub, sf, W - 152, d)[:2]:
        d.text((76, y), ln, font=sf, fill=soft)
        y += 56
    top = y + 70
    shots = {n: Image.open(os.path.join(shots_dir, n + '.png')) for n in (front_n, back_n)}
    # Big enough to run off the bottom edge, as store screenshots usually do.
    back = phone(shots[back_n], 560)
    front = phone(shots[front_n], 690)
    place(canvas, back, (W - 500, top + 130), -7)
    place(canvas, front, (24, top), 3)
    if mascot:
        m = art['mascot_dark' if dark else 'mascot']
        bbox = m.getbbox()
        m = m.crop(bbox)
        m.thumbnail((320, 320), Image.LANCZOS)
        sh = Image.new('RGBA', m.size, (0, 0, 0, 0))
        sh.putalpha(m.getchannel('A').point(lambda a: int(a * 0.25)))
        canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(14)), (W - m.size[0] - 50, H - m.size[1] - 70))
        canvas.alpha_composite(m, (W - m.size[0] - 60, H - m.size[1] - 90))
    return canvas.convert('RGB')


def feature_graphic(cfg, art, shots_dir):
    fw, fh = 1024, 500
    c1, c2, blob = cfg['light']
    canvas = gradient((fw, fh), c1, c2, blob)
    canvas.alpha_composite(decor((fw, fh), cfg['confetti'], 99, False))
    icon = rounded(art['icon'].resize((112, 112), Image.LANCZOS), 27)
    canvas.alpha_composite(icon, (64, 92))
    d = ImageDraw.Draw(canvas)
    size = 84
    while d.textlength(cfg['name'], font=font(BLACK, size)) > 480:
        size -= 2
    d.text((62, 226 + (84 - size) // 2), cfg['name'], font=font(BLACK, size), fill=hexc(cfg['ink']))
    y = 330
    for ln in wrap(cfg['tagline'], font(MEDIUM, 30), 470, d)[:2]:
        d.text((66, y), ln, font=font(MEDIUM, 30), fill=hexc(cfg['ink'], 175))
        y += 40
    shot = cfg['slides'][0][0]
    p = phone(Image.open(os.path.join(shots_dir, shot + '.png')), 250)
    place(canvas, p, (700, 70), -6)
    m = art['mascot'].crop(art['mascot'].getbbox())
    m.thumbnail((200, 200), Image.LANCZOS)
    canvas.alpha_composite(m, (590, fh - m.size[1] - 30))
    return canvas.convert('RGB')


def main(apps):
    for app in apps:
        cfg = APPS[app]
        art = render_art(app)
        store = os.path.join(ROOT, 'store', app)
        shots_dir = os.path.join(store, 'screenshots')
        icon = art['icon'].convert('RGB')
        icon.resize((512, 512), Image.LANCZOS).save(os.path.join(store, 'icon-512.png'))
        res = os.path.join(ROOT, 'apps', app, 'android/app/src/main/res')
        for density, px in MIPMAP.items():
            rounded(art['icon'].resize((px, px), Image.LANCZOS), round(px * 0.22)).save(
                os.path.join(res, f'mipmap-{density}', 'ic_launcher.png'))
        ios = os.path.join(ROOT, 'apps', app, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
        for f in os.listdir(ios):
            if f.endswith('.png'):
                px = Image.open(os.path.join(ios, f)).size[0]
                # App Store icons must be square and opaque: no rounding, no alpha.
                icon.resize((px, px), Image.LANCZOS).save(os.path.join(ios, f))
        out = os.path.join(store, 'listing-screenshots')
        os.makedirs(out, exist_ok=True)
        for f in os.listdir(out):
            os.remove(os.path.join(out, f))
        for i, spec in enumerate(cfg['slides'], 1):
            slide(cfg, art, shots_dir, spec, i).save(os.path.join(out, f'{i:02d}.png'), optimize=True)
        feature_graphic(cfg, art, shots_dir).save(os.path.join(store, 'feature-graphic.png'))
        print(app, len(cfg['slides']), 'listing screenshots, icons and feature graphic')


if __name__ == '__main__':
    main(sys.argv[1:] or [a for a in APPS if os.path.isdir(os.path.join(ROOT, 'apps', a))])
