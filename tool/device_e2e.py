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
  9. Editing an entry does not change what is shown, or deleting one does
     not stick after the app is reopened.
The session runs with system animations on, like most phones. The app's own
end-to-end tests then run on the same emulator with animations off
(tool/device_suite.sh), which covers people who turn motion off.
Each run records every check with a screenshot of the screen at that moment
(NN-PASS-... or NN-FAIL-...), and the full logcat, in OUT.

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
    try:  # the screen at the moment of the check, as proof either way
        shot(('PASS-' if ok else 'FAIL-') + re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')[:70])
    except Exception:
        pass
    return ok


def shot(name):
    SHOT[0] += 1
    path = f'{ARGS.out}/{SHOT[0]:02d}-{name}.png'
    png = adb('exec-out', 'screencap', '-p', binary=True)
    # A Fold has two screens, and screencap prints a warning ahead of the
    # picture; keep only the PNG (it is of the screen in use).
    i = png.find(b'\x89PNG')
    open(path, 'wb').write(png[i:] if i >= 0 else png)


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


def matching(pattern):
    return [n for n in nodes() if any(re.search(pattern, l) for l in n['lines'])]


def tap_match(pattern, timeout=25):
    """Taps the first node with a line matching the regex [pattern]."""
    end = time.time() + timeout
    while time.time() < end:
        hit = matching(pattern)
        if hit:
            adb('shell', 'input', 'tap', *map(str, hit[0]['center']))
            time.sleep(1.2)
            return
        time.sleep(1)
    raise RuntimeError(f'nothing matching /{pattern}/ appeared. On screen: {sorted({l for n in nodes() for l in n["lines"]})}')


def swipe(up):
    """One slow drag on the middle of the screen: up shows what is lower down."""
    out = adb('shell', 'wm', 'size', check=False)
    m = re.findall(r'(\d+)x(\d+)', out)
    w, h = map(int, m[-1]) if m else (1080, 2400)
    # user_rotation may have swapped the sides; the drag stays inside either way.
    w, h = min(w, h), min(w, h)
    y1, y2 = (int(h * 0.75), int(h * 0.35)) if up else (int(h * 0.35), int(h * 0.75))
    adb('shell', 'input', 'swipe', str(w // 2), str(y1), str(w // 2), str(y2), '600')
    time.sleep(1)


def reveal(present, tries=5):
    """Scrolls down until [present]() is true. A list only builds the rows
    near the screen, so a row lower down is invisible until scrolled to."""
    for i in range(tries + 1):
        if present():
            return True
        if i < tries:
            swipe(True)
    return False


def to_top(tries=5):
    for _ in range(tries):
        swipe(False)


def open_row(present, tap_it, title):
    """Scrolls to a row, taps it and waits for its edit screen."""
    if not reveal(present):
        raise RuntimeError(f'the row for "{title}" never appeared, even after scrolling. On screen: '
                           f'{sorted({l for n in nodes() for l in n["lines"]})}')
    tap_it()
    wait(title)


def gone(present, timeout=12):
    """Waits until [present]() is false; returns True if it went away."""
    end = time.time() + timeout
    while time.time() < end:
        if not present():
            return True
        time.sleep(1)
    return False


def delete_entry(open_it, delete_label, present, what, home):
    """Opens an entry, deletes it through the confirm dialog, then checks it
    is gone, and still gone after the app is closed and opened again."""
    open_it()
    tap(delete_label)
    wait('Cancel')  # the confirm dialog
    tap('Delete')
    to_top()
    check(f'delete: {what} is gone from the list', True, gone(lambda: reveal(present)))
    restart()
    wait(home, timeout=40)  # the list has loaded, so an absence means something
    time.sleep(2)
    check(f'delete: {what} stays gone after reopening', True, gone(lambda: reveal(present), timeout=8))
    check('still running after the delete and reopen', True, alive())


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


def pid():
    return adb('shell', 'pidof', ARGS.package, check=False).strip()


def restart():
    """Closes the app for real (a new process), then opens it again."""
    old = pid()
    adb('shell', 'am', 'force-stop', ARGS.package)
    end = time.time() + 15
    while pid() and time.time() < end:
        time.sleep(0.5)
    launch()
    end = time.time() + 20
    while pid() in ('', old) and time.time() < end:
        time.sleep(0.5)


def settled(present, timeout=25):
    """True once [present]() is true. Just after a relaunch the screen goes
    from the old window to a loading frame to the app, so poll."""
    end = time.time() + timeout
    while time.time() < end:
        if present():
            return True
        time.sleep(1)
    return False


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
    adb('shell', 'input', 'keyevent', 'KEYCODE_BACK')
    time.sleep(2)
    check(f'{name}: still running after closing the share sheet', True, alive())


def screen_changes(still_there):
    """Turns the phone sideways and back, and folds and unfolds a Fold, each
    time checking the app is alive and the entries are still on screen."""
    rotate(True)
    check('sideways: still running', True, alive())
    check('sideways: the entries are still on screen', True, still_there())
    rotate(False)
    check('upright again: the entries are still on screen', True, still_there())
    if 'fold' in ARGS.device:
        check('Fold: the emulator folds', True, 'OK' in posture(True))
        check('folded (outer screen): still running', True, alive())
        check('folded (outer screen): the entries are still on screen', True, still_there())
        posture(False)
        check('unfolded (inner screen): still running', True, alive())
        check('unfolded (inner screen): the entries are still on screen', True, still_there())


def settings_open():
    tap('Settings')
    wait('Privacy')
    check('Settings opens', True, bool(find('Privacy')))
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
    for _ in range(6):  # however many onboarding pages there are
        if find('Get started'):
            break
        tap('Next')
        time.sleep(0.8)
    check('onboarding: Next turns the pages to Get started', True, bool(find('Get started')))
    tap('Get started')
    tap('Add job')
    type_into('Job name', 'Warehouse', 0)
    type_into('Hourly rate', '20.00', 1)
    hide_keyboard()
    tap('Save')
    skip_tour()
    check('set up: the job is saved and the home screen shows', True, bool(wait('Add shift')))
    tap('Add shift')
    type_into('Date the shift starts', today(), 0)
    type_into('Start', '08:00', 1)
    type_into('End', '12:00', 2)
    hide_keyboard()
    tap('Save')
    wait('4h')
    check('add: a 08:00-12:00 shift today counts 4h this week', True, bool(find('4h')))
    row = lambda: bool(find('8:00'))  # the shift's row, below the week chart
    open_row(row, lambda: tap('8:00'), 'Edit shift')
    type_into('End', '14:00', 2)
    hide_keyboard()
    tap('Save')
    to_top()
    wait('6h')
    check('edit: changing the end to 14:00 makes it 6h', True, bool(find('6h')))
    screen_changes(lambda: bool(find('6h')))
    settings_open()
    share_sheet_opens('timesheet CSV export', lambda: (tap('Pay'), tap('CSV')))
    tap('Week')

    def after_reopen():
        wait('6h', timeout=40)
        check('after reopening: the edited 6h shift is still there', True, settled(lambda: bool(find('6h'))))
        check('after reopening: no onboarding again', False, bool(find('Get started')))
        check('after reopening: the shift row still says 8:00', True, reveal(row))
        delete_entry(lambda: open_row(row, lambda: tap('8:00'), 'Edit shift'), 'Delete shift',
                     row, 'the shift', 'Week')
    return after_reopen


def wrenchnote():
    wait('Skip', timeout=40)
    check('first screen: onboarding shows', True, bool(find('Skip')))
    tap('Skip')
    tap('Add vehicle')
    type_into('Name', 'Civic', 0)
    hide_keyboard()
    tap('Save')
    skip_tour()
    check('set up: the Civic is saved and the home screen shows', True, bool(wait('Add fill-up')))
    for km, fuel, paid in (('10000', '35', '52.50'), ('10500', '40', '60.00')):
        tap('Add fill-up')
        type_into('Date', today(), 0)
        type_into('Odometer', km, 1)
        type_into('Fuel', fuel, 2)
        type_into('Total paid', paid, 3)
        hide_keyboard()
        tap('Save')
        wait('Add fill-up')
    # The rows read "13 Nov 2026 · 10,500 km"; the odometer card at the top
    # also says "10,500 km", so match the row's dot.
    odo = r'\u00b7 *10[,.\u00a0\u202f ]?500'
    seen = lambda: bool(matching(odo))
    first = lambda: bool(matching(r'\u00b7 *10[,.\u00a0\u202f ]?000'))
    both = lambda: reveal(seen) and reveal(first)
    check('add: both fill-ups are listed (10,000 and 10,500 on the odometer)', True, both())
    open_row(seen, lambda: tap_match(odo), 'Edit fill-up')
    type_into('Total paid', '61.00', 3)
    hide_keyboard()
    tap('Save')
    wait('Add fill-up')
    paid = lambda: any('61.00' in l for n in nodes() for l in n['lines'])
    check('edit: the 10,500 fill-up now shows 61.00 paid', True, gone(lambda: not reveal(paid)))
    to_top()
    screen_changes(lambda: reveal(seen))
    settings_open()
    share_sheet_opens('cost report CSV export', lambda: (tap('Costs'), tap('CSV')))

    def after_reopen():
        wait('Civic', timeout=40)
        check('after reopening: Civic and both fill-ups are still there', True, settled(both))
        check('after reopening: the edit (61.00) is still there', True, reveal(paid))
        to_top()
        check('after reopening: no onboarding again', False, bool(find('Get started')))
        delete_entry(lambda: open_row(seen, lambda: tap_match(odo), 'Edit fill-up'), 'Delete fill-up', seen,
                     'the 10,500 fill-up', 'Civic')
        check('delete: the other fill-up (10,000) is untouched', True, reveal(first))
    return after_reopen


def housetally():
    wait('Skip', timeout=40)
    check('first screen: onboarding shows', True, bool(find('Skip')))
    tap('Skip')
    skip_tour()
    check('set up: the home screen shows', True, bool(wait('Add item')))
    tap('Add item')
    type_into('What is it?', 'Lawn mower', 0)
    hide_keyboard()
    tap('Room')
    tap('Garage')
    type_into('Price paid', '300', 5)
    hide_keyboard()
    tap('Save')
    wait('Add item')
    priced = lambda v: (lambda: any(v in l for n in nodes() for l in n['lines']))
    check('add: the lawn mower ($300.00) counts toward the home value', True, priced('300.00')())
    mower = lambda: bool(find('Lawn mower'))
    open_row(mower, lambda: tap('Lawn mower'), 'Edit item')
    type_into('Price paid', '350', 5)
    hide_keyboard()
    tap('Save')
    wait('Add item')
    to_top()
    has = priced('350.00')
    check('edit: the new price ($350.00) is counted instead', True, gone(lambda: not has()))
    screen_changes(has)
    settings_open()
    share_sheet_opens('inventory CSV export', lambda: (tap('Show menu'), tap('Spreadsheet (CSV)')))

    def after_reopen():
        wait('Add item', timeout=40)
        check('after reopening: the edited item ($350.00) is still counted', True, settled(has))
        check('after reopening: no onboarding again', False, bool(find('Get started')))
        delete_entry(lambda: open_row(mower, lambda: tap('Lawn mower'), 'Edit item'), 'Delete item',
                     mower, 'the lawn mower', 'Add item')
    return after_reopen


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
        for k in ('window_animation_scale', 'transition_animation_scale', 'animator_duration_scale'):
            adb('shell', 'settings', 'put', 'global', k, '1', check=False)
        print('screen:', adb('shell', 'wm', 'size', check=False).strip(), flush=True)
        if 'fold' in ARGS.device:
            print('fold: start unfolded:', posture(False), flush=True)
        adb('install', '-r', ARGS.apk)
        adb('logcat', '-c')
        launch()
        time.sleep(5)
        if not check('still running 8 s after launch', True, alive()):
            print(death_log())
        reopen_checks = FLOWS[ARGS.package]()
        time.sleep(8)  # the banner ad loads on the home screen meanwhile
        banner = bool(find('Ad'))
        print('banner ad on screen:', 'yes' if banner else 'no (no ad served to this emulator)', flush=True)
        check('ads: still running after the banner had time to load', True, alive())
        restart()
        reopen_checks()
        time.sleep(5)
        check('still running at the end', True, alive())
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
