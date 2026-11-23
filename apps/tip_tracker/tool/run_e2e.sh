#!/usr/bin/env bash
# Runs the end-to-end test on the Linux desktop build under a virtual display
# and leaves a checkable artifact folder:
#   test-artifacts/e2e/result.json       every expected-vs-observed check
#   test-artifacts/e2e/november.csv      the exported month (same bytes every run)
#   test-artifacts/e2e/november.pdf      the exported report (+ .txt text dump)
#   test-artifacts/e2e/tips-backup.json  the backup that was restored on the "new phone"
#   test-artifacts/e2e/checksums.txt     sha256 of the CSV
# SHOTS=<dir> also saves phone-size screenshots of the main screens.
set -euo pipefail
cd "$(dirname "$0")/.."
export TZ=${TZ_OVERRIDE:-America/Chicago}
ART="$PWD/test-artifacts/e2e"
rm -rf "$ART" && mkdir -p "$ART"
xvfb-run -a -s "-screen 0 1280x2048x24" flutter test integration_test/app_e2e_test.dart -d linux \
  --dart-define=ARTIFACT_DIR="$ART" ${SHOTS:+--dart-define=SHOTS="$SHOTS"} 2>&1 | tee "$ART/run.log"
pdftotext -layout "$ART/november.pdf" "$ART/november.txt"
grep -q '1,389.97' "$ART/november.txt" || { echo "PDF is missing the November take-home"; exit 1; }
(cd "$ART" && sha256sum november.csv > checksums.txt)
python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print('checks passed:',sum(c['pass'] for c in d['checks']),'/',len(d['checks']));sys.exit(0 if d['passed'] else 1)" "$ART/result.json"
