#!/usr/bin/env python3
"""Placeholder app icons and Play feature graphics, drawn from each app's
colour and a Material icon. Rerun after renaming an app: the feature graphic
prints the name from APPS below.

Writes:
  store/<app>/icon-512.png             Play listing icon
  store/<app>/feature-graphic.png      Play feature graphic, 1024x500
  apps/<app>/android/app/src/main/res/mipmap-*/ic_launcher.png
  apps/<app>/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png (same sizes as before)
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_FONT = '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'
BOLD = os.path.join(ROOT, 'packages/app_core/assets/fonts/Roboto-Bold.ttf')
REGULAR = os.path.join(ROOT, 'packages/app_core/assets/fonts/Roboto-Regular.ttf')

# Seed colours match each app's AppConfig; glyphs are Flutter Icons code points.
APPS = {
    'hours_tracker': ('Shift Pay', 'Hours and overtime, worked out for you', (0x00, 0x89, 0x7B), 0xe556),
    'fuel_log': ('Fuel & Service Log', 'Real fuel economy and service reminders', (0x39, 0x49, 0xAB), 0xe394),
    'home_inventory': ('Home Inventory', 'Everything you own, ready for a claim', (0x6D, 0x4C, 0x41), 0xe34a),
}
MIPMAP = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}


def icon(size, color, glyph, rounded=False):
    img = Image.new('RGBA', (size, size), color + (255,))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(ICON_FONT, int(size * 0.62))
    ch = chr(glyph)
    l, t, r, b = d.textbbox((0, 0), ch, font=font)
    d.text(((size - (r - l)) / 2 - l, (size - (b - t)) / 2 - t), ch, font=font, fill=(255, 255, 255, 255))
    if rounded:
        mask = Image.new('L', (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
        img.putalpha(mask)
    return img


def feature(name, tagline, color, glyph):
    img = Image.new('RGB', (1024, 500), color)
    img.paste(icon(220, tuple(min(255, c + 40) for c in color), glyph, rounded=True), (70, 140),
              icon(220, color, glyph, rounded=True).split()[3])
    d = ImageDraw.Draw(img)
    size = 64
    while size > 30 and d.textlength(name, font=ImageFont.truetype(BOLD, size)) > 640:
        size -= 2
    d.text((330, 170), name, font=ImageFont.truetype(BOLD, size), fill='white')
    d.text((332, 175 + size + 18), tagline, font=ImageFont.truetype(REGULAR, 30), fill=(255, 255, 255))
    return img


def main(apps):
    for app in apps:
        name, tagline, color, glyph = APPS[app]
        store = os.path.join(ROOT, 'store', app)
        os.makedirs(store, exist_ok=True)
        icon(512, color, glyph).save(os.path.join(store, 'icon-512.png'))
        feature(name, tagline, color, glyph).save(os.path.join(store, 'feature-graphic.png'))
        res = os.path.join(ROOT, 'apps', app, 'android/app/src/main/res')
        for density, px in MIPMAP.items():
            icon(px, color, glyph, rounded=True).save(os.path.join(res, f'mipmap-{density}', 'ic_launcher.png'))
        ios = os.path.join(ROOT, 'apps', app, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
        for f in os.listdir(ios):
            if f.endswith('.png'):
                px = Image.open(os.path.join(ios, f)).size[0]
                # App Store icons must be square and opaque: no rounding, no alpha.
                icon(px, color, glyph).convert('RGB').save(os.path.join(ios, f))
        print(app, 'done')


if __name__ == '__main__':
    main(sys.argv[1:] or [a for a in APPS if os.path.isdir(os.path.join(ROOT, 'apps', a))])
