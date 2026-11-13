#!/usr/bin/env python3
"""Launcher, store and web icons from brand/logo*.svg.

Writes, for the one app in apps/:
  android  mipmap-*/ic_launcher.png (legacy, rounded), mipmap-*/ic_launcher_foreground.png
           and ic_launcher_background.png (adaptive layers, 108dp), mipmap-anydpi-v26/ic_launcher.xml,
           drawable-*/splash_logo.png and the launch_background.xml files that centre it
           (Android 12+ draws its own splash from the launcher icon)
  ios      every PNG named in AppIcon.appiconset/Contents.json (square, opaque),
           and LaunchImage*.png (the logo, 96pt, centred by LaunchScreen.storyboard)
  web      web/icons/Icon-*.png, web/favicon.png
  store    store/<app>/icon-512.png and brand/logo-1024.png (used by make_store_art.py)

Needs cairosvg (python3 -m pip install cairosvg). Usage: tool/make_icons.py
"""
import io
import json
import os

import cairosvg
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND = os.path.join(ROOT, 'brand')
LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
FG_SCALE = 0.7
ADAPTIVE = {k: round(v * 108 / 48) for k, v in LEGACY.items()}  # 108dp layers
ADAPTIVE_XML = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
SPLASH = {k: v * 2 for k, v in LEGACY.items()}  # 96dp
LAUNCH_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Written by tool/make_icons.py: the logo, centred, before Flutter's first frame. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="{bg}" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash_logo" />
    </item>
</layer-list>
'''


def render(name, px):
    data = cairosvg.svg2png(url=os.path.join(BRAND, name), output_width=px, output_height=px)
    return Image.open(io.BytesIO(data)).convert('RGBA')


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius, fill=255)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main():
    app = [d for d in os.listdir(os.path.join(ROOT, 'apps')) if not d.startswith('.')][0]
    base = os.path.join(ROOT, 'apps', app)
    big = render('logo.svg', 1024)
    big.convert('RGB').save(os.path.join(BRAND, 'logo-1024.png'))
    os.makedirs(os.path.join(ROOT, 'store', app), exist_ok=True)
    big.convert('RGB').resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, 'store', app, 'icon-512.png'))

    res = os.path.join(base, 'android/app/src/main/res')
    for dens, px in LEGACY.items():
        d = os.path.join(res, f'mipmap-{dens}')
        os.makedirs(d, exist_ok=True)
        rounded(big.resize((px, px), Image.LANCZOS), round(px * 0.22)).save(os.path.join(d, 'ic_launcher.png'))
        a = ADAPTIVE[dens]
        # Launchers show the inner 72dp of a 108dp layer, so shrink the mark to
        # look the same as the legacy icon once masked.
        layer = Image.new('RGBA', (a, a), (0, 0, 0, 0))
        mark = render('logo-foreground.svg', round(a * FG_SCALE))
        layer.alpha_composite(mark, ((a - mark.size[0]) // 2, (a - mark.size[1]) // 2))
        layer.save(os.path.join(d, 'ic_launcher_foreground.png'))
        render('logo-background.svg', a).convert('RGB').save(os.path.join(d, 'ic_launcher_background.png'))
        # A plain bitmap: a <bitmap> can't point at the adaptive-icon XML.
        sd = os.path.join(res, f'drawable-{dens}')
        os.makedirs(sd, exist_ok=True)
        sp = SPLASH[dens]
        rounded(big.resize((sp, sp), Image.LANCZOS), round(sp * 0.22)).save(os.path.join(sd, 'splash_logo.png'))
    for folder, bg in (('drawable', '@android:color/white'), ('drawable-v21', '?android:colorBackground')):
        with open(os.path.join(res, folder, 'launch_background.xml'), 'w') as f:
            f.write(LAUNCH_XML.format(bg=bg))
    anydpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w') as f:
        f.write(ADAPTIVE_XML)

    ios = os.path.join(base, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    if os.path.isdir(ios):
        for img in json.load(open(os.path.join(ios, 'Contents.json')))['images']:
            pt = float(img['size'].split('x')[0])
            px = round(pt * int(img['scale'].rstrip('x')))
            big.convert('RGB').resize((px, px), Image.LANCZOS).save(os.path.join(ios, img['filename']))

    launch = os.path.join(base, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
    if os.path.isdir(launch):
        for scale, name in ((1, 'LaunchImage.png'), (2, 'LaunchImage@2x.png'), (3, 'LaunchImage@3x.png')):
            px = 96 * scale
            rounded(big.resize((px, px), Image.LANCZOS), round(px * 0.22)).save(os.path.join(launch, name))
    web = os.path.join(base, 'web')
    if os.path.isdir(web):
        for name, px, rad in [('icons/Icon-192.png', 192, 0.22), ('icons/Icon-512.png', 512, 0.22),
                              ('icons/Icon-maskable-192.png', 192, 0), ('icons/Icon-maskable-512.png', 512, 0),
                              ('favicon.png', 32, 0.22)]:
            im = big.resize((px, px), Image.LANCZOS)
            (rounded(im, round(px * rad)) if rad else im.convert('RGB')).save(os.path.join(web, name))
    print(app, 'icons written')


if __name__ == '__main__':
    main()
