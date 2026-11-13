#!/usr/bin/env bash
# Everything the emulator checks before a build may go to Play, on one device:
#   1. tool/device_e2e.py on the release APK made from the Play bundle (launch,
#      first session, sideways, fold and unfold, Settings, export, reopen).
#   2. The app's own end-to-end tests (integration_test/: create, edit and
#      delete entries, Pro screens, settings, exports, ads and consent, the
#      tour) run on the same emulator against Android's real plugins.
# Leaves in OUT: release/ (result.json, screenshots, logcat.txt),
# integration.log, integration-logcat.txt and summary.txt.
# Usage: tool/device_suite.sh <apk> <package> <app dir> <out dir> <device label>
set -uo pipefail
apk=$1 pkg=$2 app=$3 out=$4 label=$5
mkdir -p "$out"
out=$(cd "$out" && pwd)
status=0

python3 tool/device_e2e.py --apk "$apk" --package "$pkg" --out "$out/release" --device "$label" || status=1

# The tests install a debug build of the same app id: remove the release copy.
adb uninstall "$pkg" >/dev/null 2>&1 || true
# The tests expect New York time, like tool/run_e2e.sh on the desktop.
adb root >/dev/null 2>&1 || true
sleep 3
adb wait-for-device
adb shell setprop persist.sys.timezone America/New_York || true
adb logcat -c
dev=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
# The app can only write inside its own folder on a phone.
art=/data/user/0/$pkg/cache/e2e
(cd "$app" && flutter test integration_test -d "$dev" --reporter expanded \
  --dart-define=ARTIFACT_DIR="$art" \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-0000000000000000/0000000000) > "$out/integration.log" 2>&1
it=$?
tail -n 60 "$out/integration.log"
[ $it -eq 0 ] || status=1
adb logcat -d > "$out/integration-logcat.txt"
mkdir -p "$out/integration"
adb shell run-as "$pkg" tar -cf - cache/e2e 2>/dev/null | tar -xf - -C "$out/integration" 2>/dev/null || true

{
  echo "Device: $label"
  python3 - "$out/release/result.json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(f"Release APK session: {'PASS' if d['passed'] else 'FAIL'} ({sum(c['ok'] for c in d['checks'])}/{len(d['checks'])} checks)")
    for c in d['checks']:
        if not c['ok']:
            print(f"  FAIL {c['check']}: want {c['want']!r}, got {c['got']!r}")
except Exception as e:
    print(f"Release APK session: FAIL (no result: {e})")
PY
  echo "App end-to-end tests on this emulator: $([ $it -eq 0 ] && echo PASS || echo FAIL)"
  grep -E '^[0-9]+:[0-9]+ \+[0-9]+' "$out/integration.log" | tail -n 1
} | tee "$out/summary.txt"
exit $status
