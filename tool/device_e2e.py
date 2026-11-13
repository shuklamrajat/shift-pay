#!/usr/bin/env python3
"""End-to-end check of the release build on an Android emulator.

Installs the APK made from the very bundle that goes to Play, launches it
like a person would, walks a realistic first session (onboarding, set up,
log real entries), closes the app, opens it again and checks the entries
survived. It drives the app through Android's accessibility tree with
uiautomator, the same way a tester's taps reach it, so it exercises the
release code exactly as shrunk and obfuscated by R8.

What could go wrong, written down before the code:
  1. The app dies as the process starts (an R8-stripped class, a bad manifest
     entry): Nov 13, Wagebird v11 and Wrenchnote v10 closed at once on a
     Pixel Fold because R8 removed WorkManager's database class.
  2. It starts but never draws its first screen (a Dart error before runApp).
  3. It draws, then breaks on first real use: the SQLite library, the file
     paths plugin or the settings store fail only in a release build.
  4. Entries look saved but are gone after the app is closed and reopened.
  5. It crashes when reopened (a schema or settings problem on second run).
  6. The ads library crashes a few seconds after the home screen shows.
  7. Any of the above only on a large or folding screen, after turning the
     phone sideways, or when a Fold is folded or unfolded mid-session.
  8. Settings or the export/share sheet crash in the release build.
Edits, deletes and every other flow run as the app's own end-to-end tests on
the same emulator right after this (tool/device_suite.sh).
Each run records every check, screenshots and the full logcat in OUT.

Usage: device_e2e.py --apk universal.apk --package com.x.y --out out/
"""
import argparse
import json
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

ARGS = None
CHECKS = []
SHOT = [0]


def adb(*a, check=True, binary=False):
    r = subprocess.run(['adb', *a], capture_output=True, timeout=120)
    if check and r.returncode != 0:
        raise RuntimeError(f"adb {' '.join(a)} failed: {r.stderr.decode(errors='replace')}")
    return r.stdout if binary else r.stdout.decode(errors='replace')


def check(name, want, got):
    ok = want == got
    CHECKS.append({'check': name, 'want': want, 'got': got, 'ok': ok})
    print(('PASS ' if ok else 'FAIL ') + f'{name}: want {want!r}, got {got!r}', flush=True)
    return ok


def shot(name):
    SHOT[0] += 1
    path = f'{ARGS.out}/{SHOT[0]:02d}-{name}.png'
    open(path, 'wb').write(adb('exec-out', 'screencap', '-p', binary=True))


def death_log():
    """What Android logged about the app's process going away."""
    log = adb('logcat', '-d', check=False).splitlines()
    keep = [l for l in log if ARGS.package in l or ' F DEBUG' in l or 'Fatal signal' in l
            or ' F libc' in l or 'lowmemorykiller' in l or 'AndroidRuntime' in l or ' E flutter' in l]
    return '\n'.join(keep[-60:])


def alive():
    return adb('shell', 'pidof', ARGS.package, check=False).strip() != ''


def nodes(any_app=False):
    adb('shell', 'uiautomator', 'dump', '/sdcard/ui.xml', check=False)
    raw = adb('exec-out', 'cat', '/sdcard/ui.xml', check=False)
    try:
        root = ET.fromstring(raw[raw.index('<'):])
    except (ValueError, ET.ParseError):
        return []
    out = []
    for n in root.iter('node'):
        if not any_app and n.get('package') != ARGS.package:
            continue
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', n.get('bounds', ''))
        if not m:
            continue
        x1, y1, x2, y2 = map(int, m.groups())
        if x2 <= x1 or y2 <= y1:
            continue
        words = [n.get('text', ''), n.get('content-desc', ''), n.get('hint', '')]
        out.append({'lines': [l.strip() for w in words for l in w.split('\n') if l.strip()],
                    'cls': n.get('class', ''), 'center': ((x1 + x2) // 2, (y1 + y2) // 2),
                    'clickable': n.get('clickable') == 'true', 'package': n.get('package', '')})
    return out


def find(label, edit=False):
    """Nodes showing [label]: an exact line first, then a line that starts
    with it (Flutter merges a button's label with its icon's), or contains it."""
    ns = [n for n in nodes() if not edit or n['cls'].endswith('EditText')]
    for test in ((lambda l: l == label), (lambda l: l.startswith(label)), (lambda l: label in l)):
        hit = [n for n in ns if any(test(l) for l in n['lines'])]
        if hit:
            return hit
    return []


def wait(label, timeout=25, edit=False):
    end = time.time() + timeout
    while time.time() < end:
        hit = find(label, edit=edit)
        if hit:
            return hit[0]
        if not alive():
            raise RuntimeError(f'the app stopped running while waiting for "{label}"\n' + death_log())
        time.sleep(1)
    dump = sorted({l for n in nodes() for l in n['lines']})
    raise RuntimeError(f'"{label}" never appeared. On screen: {dump}')


def tap(label, timeout=25):
    n = wait(label, timeout)
    adb('shell', 'input', 'tap', *map(str, n['center']))
    time.sleep(1.2)


def type_into(label, text, idx):
    """Types into the text field labelled [label]. Some Android versions leave
    a field's label out of the accessibility dump once it holds a value, so
    after a few seconds it falls back to the [idx]th field on the form."""
    try:
        n = wait(label, timeout=6, edit=True)
    except RuntimeError:
        edits = sorted((n for n in nodes() if n['cls'].endswith('EditText')), key=lambda n: (n['center'][1], n['center'][0]))
        if len(edits) <= idx:
            raise RuntimeError(f'no field "{label}" (#{idx}); fields on screen: {[e["lines"] for e in edits]}')
        n = edits[idx]
    adb('shell', 'input', 'tap', *map(str, n['center']))
    time.sleep(0.6)
    adb('shell', 'input', 'keyevent', 'KEYCODE_MOVE_END')
    adb('shell', 'input', 'keyevent', *(['KEYCODE_DEL'] * 30))
    adb('shell', 'input', 'text', text.replace(' ', '%s'))
    time.sleep(0.6)


def hide_keyboard():
    if 'mInputShown=true' in adb('shell', 'dumpsys', 'input_method', check=False):
        adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
        time.sleep(0.8)


def launch():
    adb('shell', 'monkey', '-p', ARGS.package, '-c', 'android.intent.category.LAUNCHER', '1')
    time.sleep(3)


def restart():
    adb('shell', 'am', 'force-stop', ARGS.package)
    time.sleep(1.5)
    launch()


def rotate(landscape):
    adb('shell', 'settings', 'put', 'system', 'accelerometer_rotation', '0')
    adb('shell', 'settings', 'put', 'system', 'user_rotation', '1' if landscape else '0')
    time.sleep(3)


def posture(folded):
    """Folds or unfolds a foldable emulator (no-op answer 'KO' on a phone)."""
    r = subprocess.run(['adb', 'emu', 'fold' if folded else 'unfold'], capture_output=True, text=True, timeout=30)
    time.sleep(4)
    return r.stdout.strip()


def share_sheet_opens(name, open_it):
    """Runs [open_it], then expects Android's share sheet (another app's
    window) on top; closes it again."""
    open_it()
    end = time.time() + 20
    seen = False
    while time.time() < end and not seen:
        seen = any(n['package'] != ARGS.package for n in nodes(any_app=True))
        time.sleep(1)
    check(f'{name}: the share sheet opens', True, seen)
    shot('share-sheet')
    adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    time.sleep(2)
    check(f'{name}: still running after closing the share sheet', True, alive())


def screen_changes(still_there):
    """Turns the phone sideways and back, and folds and unfolds a Fold, each
    time checking the app is alive and the entries are still on screen."""
    rotate(True)
    check('sideways: still running', True, alive())
    check('sideways: the entries are still on screen', True, still_there())
    shot('landscape')
    rotate(False)
    check('upright again: the entries are still on screen', True, still_there())
    if 'fold' in ARGS.device:
        check('Fold: the emulator folds', True, 'OK' in posture(True))
        check('folded (outer screen): still running', True, alive())
        check('folded (outer screen): the entries are still on screen', True, still_there())
        shot('folded')
        posture(False)
        check('unfolded (inner screen): still running', True, alive())
        check('unfolded (inner screen): the entries are still on screen', True, still_there())
        shot('unfolded')


def settings_open():
    tap('Settings')
    wait('Privacy')
    check('Settings opens', True, bool(find('Privacy')))
    shot('settings')
    rotate(True)
    check('Settings sideways: still running', True, alive())
    rotate(False)
    adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    time.sleep(2)


def skip_tour():
    tap('Skip')


def today():
    return adb('shell', 'date', '+%Y-%m-%d').strip()


# ---- One realistic first session per app ----------------------------------

def wagebird():
    wait('Next', timeout=40)
    check('first screen: onboarding shows', True, bool(find('Next')))
    shot('first-screen')
    for _ in range(6):  # however many onboarding pages there are
        if find('Get started'):
            break
        tap('Next')
        time.sleep(0.8)
    tap('Get started')
    tap('Add job')
    type_into('Job name', 'Warehouse', 0)
    type_into('Hourly rate', '20.00', 1)
    hide_keyboard()
    tap('Save')
    skip_tour()
    shot('home-after-setup')
    tap('Add shift')
    type_into('Date the shift starts', today(), 0)
    type_into('Start', '08:00', 1)
    type_into('End', '12:00', 2)
    hide_keyboard()
    tap('Save')
    wait('4h')
    check('a 08:00-12:00 shift today counts 4h this week', True, bool(find('4h')))
    shot('shift-logged')
    screen_changes(lambda: bool(find('4h')))
    settings_open()
    share_sheet_opens('timesheet CSV export', lambda: (tap('Pay'), tap('CSV')))
    tap('Week')
    return lambda: (wait('4h', timeout=40), check('after reopening: the shift is still there', True, bool(find('4h'))),
                    check('after reopening: no onboarding again', False, bool(find('Get started'))))


def wrenchnote():
    wait('Skip', timeout=40)
    check('first screen: onboarding shows', True, bool(find('Skip')))
    shot('first-screen')
    tap('Skip')
    tap('Add vehicle')
    type_into('Name', 'Civic', 0)
    hide_keyboard()
    tap('Save')
    skip_tour()
    shot('home-after-setup')
    for km, fuel, paid in (('10000', '35', '52.50'), ('10500', '40', '60.00')):
        tap('Add fill-up')
        type_into('Date', today(), 0)
        type_into('Odometer', km, 1)
        type_into('Fuel', fuel, 2)
        type_into('Total paid', paid, 3)
        hide_keyboard()
        tap('Save')
        wait('Add fill-up')
    seen = lambda: any(re.search(r'10[,.  ]?500', l) for n in nodes() for l in n['lines'])
    check('the second fill-up (10,500 on the odometer) is listed', True, seen())
    shot('fill-ups-logged')
    screen_changes(seen)
    settings_open()
    share_sheet_opens('cost report CSV export', lambda: (tap('Costs'), tap('CSV')))
    return lambda: (wait('Civic', timeout=40), check('after reopening: Civic and its fill-ups are still there', True, seen()),
                    check('after reopening: no onboarding again', False, bool(find('Get started'))))


def housetally():
    wait('Skip', timeout=40)
    check('first screen: onboarding shows', True, bool(find('Skip')))
    shot('first-screen')
    tap('Skip')
    skip_tour()
    shot('home-after-setup')
    tap('Add item')
    type_into('What is it?', 'Lawn mower', 0)
    hide_keyboard()
    tap('Room')
    tap('Garage')
    type_into('Price paid', '300', 5)
    hide_keyboard()
    tap('Save')
    wait('Add item')
    has = lambda: any('300.00' in l for n in nodes() for l in n['lines'])
    check('the lawn mower ($300.00) counts toward the home value', True, has())
    shot('item-logged')
    screen_changes(has)
    settings_open()
    share_sheet_opens('inventory CSV export', lambda: (tap('Show menu'), tap('Spreadsheet (CSV)')))
    return lambda: (wait('Add item', timeout=40), check('after reopening: the item is still counted', True, has()),
                    check('after reopening: no onboarding again', False, bool(find('Get started'))))


FLOWS = {'com.shuklamrajat.wagebird': wagebird, 'com.shuklamrajat.wrenchnote': wrenchnote,
         'com.shuklamrajat.housetally': housetally}


def crashes(log):
    return [l for l in log.splitlines()
            if ('FATAL EXCEPTION' in l or 'Fatal signal' in l or 'ANR in ' + ARGS.package in l
                or f'Process: {ARGS.package}' in l)]


def main():
    global ARGS
    p = argparse.ArgumentParser()
    p.add_argument('--apk', required=True)
    p.add_argument('--package', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--device', default='emulator')
    ARGS = p.parse_args()
    subprocess.run(['mkdir', '-p', ARGS.out], check=True)
    error = None
    try:
        adb('install', '-r', ARGS.apk)
        adb('logcat', '-c')
        launch()
        time.sleep(5)
        if not check('still running 8 s after launch', True, alive()):
            print(death_log())
        reopen_checks = FLOWS[ARGS.package]()
        time.sleep(8)  # the banner ad loads on the home screen meanwhile
        check('still running on the home screen after 8 s more', True, alive())
        restart()
        reopen_checks()
        shot('after-reopen')
        time.sleep(5)
        check('still running after reopening', True, alive())
    except Exception as e:  # recorded as a failed check, with what was on screen
        error = str(e)
        check('the session finished without an error', None, error)
        try:
            shot('at-failure')
        except Exception:
            pass
    log = adb('logcat', '-d', check=False)
    open(f'{ARGS.out}/logcat.txt', 'w').write(log)
    found = crashes(log)
    check('logcat has no crash for this app', [], found[:5])
    if found:
        start = log.find('FATAL EXCEPTION')
        print(log[start:start + 4000] if start >= 0 else '\n'.join(found))
    result = {'package': ARGS.package, 'device': ARGS.device, 'apk': ARGS.apk,
              'passed': all(c['ok'] for c in CHECKS), 'checks': CHECKS}
    json.dump(result, open(f'{ARGS.out}/result.json', 'w'), indent=2)
    print(f"{sum(c['ok'] for c in CHECKS)}/{len(CHECKS)} checks passed on {ARGS.device}")
    sys.exit(0 if result['passed'] else 1)


if __name__ == '__main__':
    main()
