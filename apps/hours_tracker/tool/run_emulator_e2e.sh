#!/usr/bin/env bash
# Runs every end-to-end journey on a booted Android emulator (or phone) and
# leaves a checkable artifact folder:
#   test-artifacts/emulator/<suite>/result.json  every expected-vs-observed check
#   test-artifacts/emulator/<suite>.log           the flutter drive output
#   test-artifacts/emulator/video/*.mp4           screen recording of the whole run
#   test-artifacts/emulator/summary.md            pass/fail per suite
# Used by .github/workflows/android-emulator.yml; also works locally with
# one emulator running (adb devices shows it).
set -uo pipefail
cd "$(dirname "$0")/.."
PKG=com.shuklamrajat.wagebird
OUT="$PWD/test-artifacts/emulator"
DEV_ART="/data/user/0/$PKG/cache/e2e"
rm -rf "$OUT" && mkdir -p "$OUT/video"

adb wait-for-device
adb root >/dev/null 2>&1 && sleep 3 && adb wait-for-device
# The journeys' hand-worked numbers include a US daylight-saving night.
adb shell settings put global auto_time_zone 0 || true
adb shell cmd alarm set-timezone America/New_York 2>/dev/null || adb shell setprop persist.sys.timezone America/New_York
echo "device time zone: $(adb shell getprop persist.sys.timezone)" | tee "$OUT/device.txt"
adb shell getprop ro.build.version.release | sed 's/^/android /' >> "$OUT/device.txt"

# Screen recording in back-to-back segments (screenrecord stops at 3 minutes).
( i=0; while :; do i=$((i+1)); adb shell screenrecord --bit-rate 3000000 --time-limit 170 "/sdcard/e2e-$(printf %02d $i).mp4" || break; done ) &
REC=$!

run() {
  local name=$1 target=$2; shift 2
  echo "::group::$name ($target)"
  flutter drive --debug -d emulator-5554 --driver=test_driver/integration_test.dart --target="$target" \
    --dart-define=ARTIFACT_DIR="$DEV_ART/$name" "$@" 2>&1 | tee "$OUT/$name.log"
  echo "${PIPESTATUS[0]}" > "$OUT/$name.exit"
  echo "::endgroup::"
  adb exec-out run-as "$PKG" tar c -C cache/e2e "$name" 2>/dev/null | tar x -C "$OUT" 2>/dev/null \
    || adb pull "$DEV_ART/$name" "$OUT/" >/dev/null 2>&1 || true
}

run device integration_test/android_device_e2e_test.dart
run app integration_test/app_e2e_test.dart --dart-define=SHOTS="$DEV_ART/app/screens"
run free_build integration_test/free_build_e2e_test.dart
run ads integration_test/ads_e2e_test.dart --dart-define=ADMOB_BANNER_ID=ca-app-pub-0000000000000000/0000000000
run tour integration_test/tour_e2e_test.dart

kill $REC 2>/dev/null; adb shell pkill -INT screenrecord 2>/dev/null; sleep 4
for f in $(adb shell ls /sdcard/ | tr -d '\r' | grep '^e2e-.*\.mp4$'); do adb pull "/sdcard/$f" "$OUT/video/" >/dev/null; done
python3 tool/emulator_summary.py "$OUT"
