#!/usr/bin/env python3
"""Sums up an emulator end-to-end run: every result.json under the folder,
plus suites that crashed before writing one. Writes summary.md and
summary.json, appends to the GitHub job summary, and exits 1 on any failure."""
import json, os, pathlib, sys

out = pathlib.Path(sys.argv[1])
rows, failed = [], False
for exit_file in sorted(out.glob('*.exit')):
    suite = exit_file.stem
    code = exit_file.read_text().strip()
    results = sorted((out / suite).rglob('result.json')) if (out / suite).exists() else []
    if not results:
        rows.append({'suite': suite, 'scenario': '(no result.json written)', 'passed': 0, 'total': 0, 'ok': False,
                     'exit': code, 'failures': []})
        failed = True
        continue
    for r in results:
        d = json.loads(r.read_text())
        checks = d.get('checks', [])
        bad = [c for c in checks if not c.get('pass')]
        ok = d.get('passed', False) and not bad and code == '0'
        failed |= not ok
        rows.append({'suite': suite, 'scenario': d.get('scenario', ''), 'passed': len(checks) - len(bad),
                     'total': len(checks), 'ok': ok, 'exit': code,
                     'failures': [{'name': c['name'], 'expected': c.get('expected'), 'observed': c.get('observed')} for c in bad]})

lines = ['| Suite | Scenario | Checks | Result |', '|---|---|---|---|']
for r in rows:
    lines.append(f"| {r['suite']} | {r['scenario']} | {r['passed']}/{r['total']} | {'PASS' if r['ok'] else 'FAIL (exit ' + r['exit'] + ')'} |")
for r in rows:
    for f in r['failures']:
        lines.append(f"\n- **{r['suite']}** `{f['name']}`: expected `{f['expected']}`, observed `{f['observed']}`")
md = '\n'.join(lines) + '\n'
(out / 'summary.md').write_text(md)
(out / 'summary.json').write_text(json.dumps({'ok': not failed, 'suites': rows}, indent=2))
if os.environ.get('GITHUB_STEP_SUMMARY'):
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as fh:
        fh.write('## Emulator end-to-end\n\n' + md)
print(md)
sys.exit(1 if failed else 0)
