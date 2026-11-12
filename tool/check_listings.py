#!/usr/bin/env python3
"""Checks each store/<app>/listing.md against Google Play's limits: app name
30, short description 80, full description 4000 characters, and that every
listed screenshot file exists at 1080x1920."""
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ok = True
for app in [a for a in ('hours_tracker', 'fuel_log', 'home_inventory') if os.path.isdir(os.path.join(ROOT, 'apps', a))]:
    d = os.path.join(ROOT, 'store', app)
    md = open(os.path.join(d, 'listing.md')).read()
    name = re.search(r'\| App name \(30\) \| (.+?) \|', md).group(1)
    short = re.search(r'\| Short description \(80\) \| (.+?) \|', md).group(1)
    desc = re.search(r'## Full description\n\n```text\n(.*?)\n```', md, re.S).group(1)
    shots = re.findall(r'`(listing-screenshots/\d+\.png)`', md)
    problems = []
    if len(name) > 30: problems.append(f'name {len(name)} > 30')
    if len(short) > 80: problems.append(f'short {len(short)} > 80')
    if len(desc) > 4000: problems.append(f'description {len(desc)} > 4000')
    if not 2 <= len(shots) <= 8: problems.append(f'{len(shots)} screenshots, Play takes 2 to 8')
    for s in shots:
        p = os.path.join(d, s)
        if not os.path.exists(p) or Image.open(p).size != (1080, 1920): problems.append(f'{s} missing or not 1080x1920')
    fg = os.path.join(d, 'feature-graphic.png')
    if Image.open(fg).size != (1024, 500): problems.append('feature graphic not 1024x500')
    print(f"{app}: name {len(name)}, short {len(short)}, description {len(desc)}, {len(shots)} screenshots"
          + (f"  PROBLEMS: {'; '.join(problems)}" if problems else '  ok'))
    ok &= not problems
sys.exit(0 if ok else 1)
