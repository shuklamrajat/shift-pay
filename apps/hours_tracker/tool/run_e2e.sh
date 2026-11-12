#!/usr/bin/env bash
# Runs the end-to-end test on the Linux desktop build under a virtual display
# and leaves a checkable artifact folder:
#   test-artifacts/e2e/result.json   every expected-vs-observed check
#   test-artifacts/e2e/timesheet.csv the exported CSV
#   test-artifacts/e2e/timesheet.pdf the exported PDF (+ .txt text dump)
#   test-artifacts/e2e/checksums.txt sha256 of the CSV (same on every run)
set -euo pipefail
cd "$(dirname "$0")/.."
export TZ=America/New_York
ART="$PWD/test-artifacts/e2e"
rm -rf "$ART" && mkdir -p "$ART"
xvfb-run -a flutter test integration_test/app_e2e_test.dart -d linux \
  --dart-define=ARTIFACT_DIR="$ART" 2>&1 | tee "$ART/run.log"
pdftotext -layout "$ART/timesheet.pdf" "$ART/timesheet.txt"
grep -q '1,425.00' "$ART/timesheet.txt" || { echo "PDF is missing the total pay"; exit 1; }
(cd "$ART" && sha256sum timesheet.csv > checksums.txt)
# The build as it ships today (Pro free until billing is live, privacy link).
mkdir -p "$ART/free_build"
xvfb-run -a flutter test integration_test/free_build_e2e_test.dart -d linux \
  --dart-define=ARTIFACT_DIR="$ART/free_build" 2>&1 | tee "$ART/free_build/run.log"
python3 -c "import json,sys;d=json.load(open('$ART/free_build/result.json'));print('free build checks passed:',sum(c['pass'] for c in d['checks']),'/',len(d['checks']));sys.exit(0 if d['passed'] else 1)"
python3 -c "import json,sys;d=json.load(open('$ART/result.json'));print('checks passed:',sum(c['pass'] for c in d['checks']),'/',len(d['checks']));sys.exit(0 if d['passed'] else 1)"
