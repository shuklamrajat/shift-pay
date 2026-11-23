# Tip tracker: user stories, screen map and edge cases

App name: Tipwell (com.studioswiddle.tipwell), picked by Rajat on 23 Nov 2026.
Written 23 Nov 2026, before any code. Research behind it: `docs/research.md`.

## Who uses it, day in and day out

| Person | When they open it | What they need in that moment |
|---|---|---|
| Server (main user) | End of every shift, often after midnight, tired, phone in one hand | Log the night in under 30 seconds: hours, cash, card, tip-out. See what they really made per hour. |
| Bartender | Same, plus they tip out barbacks and get tipped out by servers | Tip-out paid AND tip-in received. Cash heavy. |
| Delivery / gig driver | After a block of orders | Hours plus tips, often only one kind (app tips). No tip-out. |
| Two-job worker | Any shift | Pick the job fast, keep the jobs' numbers apart, compare them. |
| Everyone, weekly | Payday, or arguing with a manager about a short paycheck | Card tips owed on this paycheck vs cash already taken home, for the pay period. |
| Everyone, yearly | Tax time | Year totals, cash vs card, as a PDF or CSV for a tax preparer. |
| Everyone, rarely | New phone, phone wiped, app reinstalled | Get every shift back. This is the moment competitors fail (see research). |

## The promise (what makes it different)

1. **Your tips never disappear.** No account, no server, no login to get locked out of. Automatic daily backup on the phone, one-tap backup file you can save anywhere, restore that shows what you are about to get back before it touches anything.
2. **30-second logging.** Only hours are required. Cash only, card only, or no tips at all are all fine (no forced cash+card, no $0.01 trick).
3. **Tip-out done for you.** Each job has its rule (% of sales, % of tips, or a flat amount). The app fills it in; you can override for one night.
4. **Real hourly rate.** Wage plus tips minus tip-out, divided by hours, for every shift, week and job. Best night of the week at a glance.
5. **History is never rewritten.** Wage and tip-out rule are saved on each shift, so a raise or a new rule never changes old nights.

## There is no login

What happens when they "log in": nothing to log into. First launch goes to a short welcome, then a one-screen job setup. Every later launch opens straight on the Shifts tab. This is deliberate: sign-in lockouts and "new account, data gone" are the main complaints about ServerLife, TipSee and Just the Tips.

## Screen map: every button and what Back does

Android Back and the app bar back arrow do the same thing everywhere.

### 0. App launch
- First launch: Welcome (3 pages) → Job setup → Shifts tab.
- Later launches: run the database health check (see Backups), then Shifts tab.
- If the health check fails: "Your data needs repair" screen with Restore latest backup (primary) and Export what's readable. Back closes the app (we never show a half-broken list).

### 1. Welcome (first launch only)
| Control | Does |
|---|---|
| Next | Next page (log every shift / tip-out done for you / never lose a night) |
| Skip | Jumps to Job setup |
| Get started (last page) | Job setup |
| Back | Previous page; on page 1 leaves the app (Android) |

### 2. Job setup (first launch) / New job / Edit job
Fields: Job name (required, e.g. "Olive Garden"), Role chips (Server, Bartender, Delivery, Other; sets sensible defaults), Hourly wage (optional, defaults 0), Tip-out rule (None / % of sales / % of tips / flat amount, with value), Track sales toggle (on automatically when the rule is % of sales), Pay period (weekly / every two weeks / twice a month, plus start day), Colour.

| Control | Does |
|---|---|
| Save | Validates (name not empty, not a duplicate of an active job, %, 0-100, money ≥ 0), saves, returns to where it came from. First-run version goes to Shifts tab. |
| Skip (first run only) | Creates a job called "My job" with no wage and no tip-out, goes to Shifts. |
| New phone? Restore your backup (first run only) | File picker → same preview and checks as Backup & restore → the app opens with everything restored. Someone moving phones never has to make a fake job first. |
| Archive (edit only, menu) | Hides the job from the picker; all its shifts stay and still count in stats. Snackbar with Undo. |
| Restore (archived job) | Puts it back in the picker. |
| Delete (edit only, menu) | Only for a job with no shifts. A job with shifts offers Archive instead and says why. |
| Back with unsaved changes | "Discard changes?" Keep editing / Discard. On first run, Back leaves the app (nothing is half saved). |

### 3. Shifts tab (home)
Top: this week's take-home, hours and $/hr card (count-up animation), with a pay-period chip.
List: shifts grouped by week, newest first, each row shows day, job colour dot, hours, take-home, $/hr. Week header shows that week's totals.

| Control | Does |
|---|---|
| + Log shift (FAB) | Shift editor, new shift, last used job preselected, date = today (or yesterday if before 5 AM: the after-midnight close) |
| Tap a shift | Shift editor in edit mode |
| Long-press a shift | Menu: Duplicate (opens editor pre-filled with today's date), Delete (snackbar Undo) |
| Job filter chip | All jobs / one job |
| Empty state | Illustration + "Log your first shift" button (same as FAB) |
| Bottom tabs | Shifts / Stats / Jobs / Settings. Selected tab keeps its scroll position. |
| Back | From Shifts tab: leaves the app. From any other tab: goes to Shifts tab first. |

### 4. Shift editor (the screen used most)
Order on screen is the order people think after a shift: Job → Date → Hours → Tips → Tip-out → Notes. A live summary card at the bottom updates as they type.

| Field | Rules |
|---|---|
| Job | Chips of active jobs; "+ New job" chip opens New job and comes back with it selected |
| Date | Defaults as above; date picker; future dates blocked |
| Hours | Two modes, toggle remembered: Start/End times (overnight allowed: end before start means next day) or just hours worked (0.25 steps). Unpaid break (minutes) in Start/End mode. Required: worked time > 0. Over 16 h shows a "Long shift, is that right?" warning; over 24 h blocked. |
| Cash tips | Optional, money keyboard |
| Card tips | Optional |
| Tip-in received | Optional (bartenders tipped out by servers) |
| Sales | Shown when the job tracks sales; needed for a % of sales rule |
| Tip-out | Filled from the job rule, shows the rule ("3% of sales"). Tap to type a different amount for tonight (marked "edited"); Reset puts the rule back. Cannot exceed total tips + tip-in when the rule is % of tips. % of sales may exceed tips (it happens) and shows a warning, not a block. |
| Notes | Free text, 500 chars |

Summary card: Tips (cash + card + tip-in) − tip-out = tips kept; wage × hours = wages; total; $/hr. Cash in pocket tonight (cash + tip-in − cash tip-out) shown under it.

| Control | Does |
|---|---|
| Save | Validates, saves in one transaction, returns to the list with the new row highlighted and a short confetti burst on the first ever shift and on a best-ever $/hr |
| Delete (edit mode, menu) | Confirm dialog, deletes, list shows Undo snackbar for 6 s |
| Duplicate (edit mode, menu) | Saves nothing; opens a new editor pre-filled with this shift's job, hours and times, date today |
| Back with nothing typed | Leaves, nothing saved |
| Back with changes | "Discard this shift?" Keep editing / Discard |
| App killed mid-entry | Draft kept; next time the editor opens: "Finish the shift you started?" Resume / Discard |

### 5. Stats tab
One page, no jumping to other screens (a ServerLife complaint). Period switcher at top: Week / Month / Year / All, with ‹ › to step back and forward.

Shows: take-home, hours, $/hr, shift count (count-up); tips over time bar chart; cash vs card vs wages split bar; by job (when more than one); best day of the week by $/hr; tip-out total; tax set-aside estimate (uses the % in Settings, labelled as an estimate).

| Control | Does |
|---|---|
| Week/Month/Year/All | Switches period, charts redraw |
| ‹ › | Previous / next period; › disabled at the current period |
| Tap a bar | Shows that day/week/month's numbers in a tooltip |
| Export this period | CSV or PDF of the shown period (share sheet) |
| Back | Goes to Shifts tab |

### 6. Jobs tab
Active jobs list (colour, wage, rule, this month's take-home), then a collapsed "Archived" section.

| Control | Does |
|---|---|
| + Add job | New job screen |
| Tap job | Edit job |
| Back | Shifts tab |

### 7. Settings tab
Backup & restore (top, with "Last backup" status), Week starts on, Pay period (+ a start day for weekly / every two weeks), Tax set-aside %, Currency, Theme, Take the tour, Privacy policy, About.

### 7b. Repair screen (only if the launch check finds damage)
Shown instead of the app when SQLite's integrity or foreign-key check fails. Offers: Restore the newest backup on the phone, Restore from a file, older backups, or Open the app anyway. Nothing changes without a tap, and no daily backup is made of damaged data.

### 8. Backup & restore screen
| Control | Does |
|---|---|
| Status card | Last backup time, and when a backup last left the phone ("Never saved off this phone" until the first share) |
| Back up now | Writes a backup file and opens the share sheet (Drive, email, Files) |
| Restore from file | File picker → preview: "This backup has 214 shifts from 3 Jan 2025 to 22 Nov 2026, 2 jobs, made 22 Nov 2026" → Replace my data (danger) / Cancel. Before replacing, a safety copy of today's data is saved automatically, and the screen says so. |
| Backups on this phone | Daily copies (newest 14), safety copies made before a restore (newest 5), copies made before an update, and ones you saved. Tap any → same preview → Replace. Restoring a safety copy undoes a restore. |
| Automatic backups toggle | On by default |
| Export CSV (all shifts) | Spreadsheet of every shift |
| Back | Settings |

## Backups and keeping the database healthy

- SQLite with foreign keys on, every write in a transaction, money stored as whole cents (no rounding drift), times stored as local date + minutes.
- Each shift stores the wage and tip-out rule used that night.
- **Automatic backup:** on app start and after saves, at most once a day, a full JSON snapshot is written to the app's private folder; keep the newest 14, delete older.
- **Before every schema upgrade** a snapshot is written first (an update must never be able to wipe history: the Just the Tips and Tip Bucket complaints).
- **Before every restore** a snapshot of the current data is written first.
- **Backup file format:** one JSON file with `format`, `formatVersion`, `appVersion`, `createdAt`, counts, `sha256` of the data section, jobs and shifts. Restore checks the format, version, checksum and that every shift's job exists, all before deleting anything; then replaces everything in one transaction. A bad file changes nothing and says what is wrong.
- **Health check on launch:** `PRAGMA integrity_check` and `foreign_key_check`. Failure goes to the repair screen.
- CSV export for spreadsheets is separate from backup (backup restores, CSV is for reading).

## Edge cases (each one has a defined behaviour above or here)

1. Shift after midnight: date defaults to yesterday before 5 AM; end time before start = next day.
2. Hours-only shift with no tips (delivery wait time, training shift): saves fine.
3. Tips with no hours: blocked (can't compute $/hr); message says enter at least the hours.
4. Only card tips, only cash tips: fine.
5. Tip-out more than tips: allowed for % of sales with a warning; blocked for % of tips.
6. Shift longer than 24 h: blocked. Longer than 16 h: warning.
7. Two shifts on the same day (doubles, split shifts): allowed, both shown, week totals add up.
8. Wage raise: change the job's wage; only new shifts use it.
9. Tip-out rule changes: same, old shifts keep their rule.
10. Archiving a job: shifts stay in history and stats; job leaves the picker.
11. Deleting a job with shifts: not allowed; Archive offered.
12. Deleting a shift by mistake: Undo for 6 s.
13. App killed while typing: draft resumes.
14. Backup file from a newer app version: refused with "Update the app to restore this backup".
15. Backup file edited or truncated: checksum fails, nothing changes.
16. Restoring a backup older than current data: preview shows dates so the person sees it; safety copy made first.
17. Phone storage full while backing up: error shown, existing data untouched.
18. Currency change: display only, numbers unchanged.
19. Week start differs per job pay period: stats week follows the Settings week start; pay period card follows the selected job.
20. Huge numbers or pasted text in money fields: input limited to digits and one decimal point, max 99,999.99 per field.
21. Empty states everywhere (no shifts, no jobs in a period, a stats period with nothing).
22. Reduced motion: animations jump to the end.

## Out of scope for this first build (noted, not forgotten)

- Shift reminders (needs the notifications plugin; next build).
- Clock in / clock out live timer (Wagebird has it; add after the core is solid).
- Paycheck reconciliation screen (mark card tips as paid on a paycheck).
- Tip pools by points.
- Importing from other apps.
