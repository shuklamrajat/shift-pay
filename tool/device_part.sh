#!/usr/bin/env bash
# One part of the emulator gate, on one device. Runs inside the emulator step.
#   release: tool/device_e2e.py on the APK made from the Play bundle (launch,
#            onboarding, add, edit, delete, sideways, fold and unfold,
#            Settings, export, ads, reopen with the data kept).
#   tests:   the app's own end-to-end tests (integration_test/), one file at a
#            time, each with its own time limit.
# Exit codes, written to $STATUS_FILE as well:
#   0 everything passed
#   1 the app crashed or froze, or a check or test failed: never retried
#   3 the emulator stopped answering (a test machine problem): CI retries once
# Usage: tool/device_part.sh <release|tests> <apk> <package> <app dir> <out dir> <device label>
set -uo pipefail
part=$1 apk=$2 pkg=$3 app=$4 out=$5 label=$6
rm -rf "$out"
mkdir -p "$out"
out=$(cd "$out" && pwd)
status_file=${STATUS_FILE:-$out/status}

device_ok() {
  [ "$(timeout 20 adb get-state 2>/dev/null)" = device ] &&
    [ "$(timeout 20 adb shell echo ok 2>/dev/null | tr -d '\r')" = ok ]
}
app_crashed() {  # crash or freeze lines that belong to the app's own process
  grep -A3 'FATAL EXCEPTION' "$1" 2>/dev/null | grep -q "Process: $pkg" ||
    grep -qE "ANR in $pkg|(Fatal signal|>>> ).*$pkg" "$1" 2>/dev/null
}
finish() {
  echo "$1" > "$status_file"
  case $1 in
    0) echo "RESULT: $part on $label passed" ;;
    3) echo "RESULT: $part on $label stopped because the emulator stopped answering (test machine, not the app)" ;;
    *) echo "RESULT: $part on $label FAILED" ;;
  esac | tee -a "$out/summary.txt"
  exit 0  # the workflow reads the status file, so a retry can follow
}

echo "Device: $label, part: $part" > "$out/summary.txt"
device_ok || finish 3
# Right after boot, Android itself is busy (its launcher stalls on this
# machine). Let it calm down first: up to 3 minutes, until the load is low.
for i in $(seq 1 36); do
  load=$(timeout 10 adb shell cat /proc/loadavg 2>/dev/null | cut -d' ' -f1)
  echo "emulator load: ${load:-?}"
  awk -v l="${load:-99}" 'BEGIN { exit !(l < 2.5) }' && break
  sleep 5
done
# Android's own parts (its launcher, its SDK setup app) stall on this machine
# and their "isn't responding" dialogs cover the app. Hide those dialogs and
# switch off the setup app. A freeze of the app itself is still caught: it is
# logged as "ANR in <app>", which fails the run.
timeout 10 adb shell settings put global hide_error_dialogs 1 || true
timeout 20 adb shell pm disable-user --user 0 com.google.android.googlesdksetup >/dev/null 2>&1 || true
timeout 10 adb shell input keyevent KEYCODE_HOME || true

if [ "$part" = release ]; then
  # Start from a phone that has never seen the app, so the install, the first
  # screen and the "no onboarding after reopening" checks mean what they say.
  timeout 60 adb uninstall "$pkg" >/dev/null 2>&1 || true
  timeout 1500 python3 tool/device_e2e.py --apk "$apk" --package "$pkg" --out "$out/release" --device "$label"
  rc=$?
  python3 - "$out/release/result.json" >> "$out/summary.txt" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(f"Release APK session: {sum(c['ok'] for c in d['checks'])}/{len(d['checks'])} checks passed")
    for c in d['checks']:
        if not c['ok']:
            print(f"  FAIL {c['check']}: want {c['want']!r}, got {str(c['got'])[:300]!r}")
except Exception as e:
    print(f"Release APK session: no result ({e})")
PY
  if [ $rc -eq 124 ]; then  # the 25-minute limit
    timeout 60 adb logcat -d > "$out/release/logcat.txt" 2>/dev/null
    if app_crashed "$out/release/logcat.txt"; then rc=1; elif device_ok; then rc=1; else rc=3; fi
  fi
  # The session script itself died without a result: it was the emulator if
  # the emulator no longer answers and the app logged no crash.
  if [ ! -f "$out/release/result.json" ] && ! device_ok && ! app_crashed "$out/release/logcat.txt"; then rc=3; fi
  [ $rc -eq 0 ] || [ $rc -eq 3 ] || rc=1
  finish $rc
fi

# The app's own tests. They install a debug build of the same app id.
timeout 60 adb uninstall "$pkg" >/dev/null 2>&1 || true
timeout 30 adb root >/dev/null 2>&1 || true
sleep 3
timeout 90 adb wait-for-device || finish 3
# The tests expect New York time, like tool/run_e2e.sh on the desktop.
timeout 20 adb shell setprop persist.sys.timezone America/New_York || true
dev=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
[ -n "$dev" ] || finish 3
# The app can only write inside its own folder on a phone.
art=/data/user/0/$pkg/cache/e2e
status=0
for t in "$app"/integration_test/*_test.dart; do
  name=$(basename "$t" .dart)
  if ! device_ok; then
    echo "$name: not run, the emulator stopped answering" | tee -a "$out/summary.txt"
    [ $status -eq 0 ] && status=3
    break
  fi
  timeout 30 adb logcat -c 2>/dev/null || true
  start=$(date +%s)
  (cd "$app" && timeout 900 flutter test "integration_test/$name.dart" -d "$dev" --reporter expanded \
    --dart-define=ARTIFACT_DIR="$art" \
    --dart-define=ADMOB_BANNER_ID=ca-app-pub-0000000000000000/0000000000) > "$out/$name.log" 2>&1
  rc=$?
  timeout 60 adb logcat -d > "$out/$name-logcat.txt" 2>/dev/null || true
  mkdir -p "$out/files/$name"
  timeout 60 adb shell run-as "$pkg" tar -cf - cache/e2e 2>/dev/null | tar -xf - -C "$out/files/$name" 2>/dev/null || true
  secs=$(( $(date +%s) - start ))
  if [ $rc -eq 0 ]; then
    echo "PASS $name (${secs}s)" | tee -a "$out/summary.txt"
  elif app_crashed "$out/$name-logcat.txt"; then
    echo "FAIL $name: the app crashed or froze (${secs}s)" | tee -a "$out/summary.txt"
    status=1
  elif ! device_ok; then
    echo "STOPPED $name: the emulator stopped answering (${secs}s)" | tee -a "$out/summary.txt"
    [ $status -eq 0 ] && status=3
    break
  else
    echo "FAIL $name (${secs}s$([ $rc -eq 124 ] && echo ', over its 15-minute limit')):" | tee -a "$out/summary.txt"
    grep -E '══╡|Expected:|Actual:|Which:|^\s*#[0-9] |The following' "$out/$name.log" | head -n 25 | tee -a "$out/summary.txt"
    status=1
  fi
  timeout 60 adb uninstall "$pkg" >/dev/null 2>&1 || true
done
finish $status
