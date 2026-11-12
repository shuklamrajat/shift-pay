#!/usr/bin/env bash
# Phone-size store screenshots (1080x1920). Runs each app's end-to-end test at
# phone size and saves pictures at chosen moments; the run still fails if any
# check fails, so the pictures always show a working app.
# Output: store/<app>/screenshots/*.png and store/<app>/screenshots/result.json
set -euo pipefail
cd "$(dirname "$0")/.."
export TZ=America/New_York
for app in ${@:-$(ls apps)}; do
  out="$PWD/store/$app/screenshots"
  rm -rf "$out" && mkdir -p "$out"
  (cd "apps/$app" && xvfb-run -a flutter test integration_test/app_e2e_test.dart -d linux \
    --dart-define=ARTIFACT_DIR="$out/e2e" --dart-define=SHOTS="$out" > "$out/run.log" 2>&1) \
    || { echo "$app: test failed at phone size, see $out/run.log"; exit 1; }
  echo "$app: $(ls "$out"/*.png | wc -l) screenshots"
done
