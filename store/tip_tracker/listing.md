# Tipwell: Google Play listing

Ready to paste into Play Console (Main store listing). Character counts are
checked by `tool/check_listings.py`. Keywords come from the tip tracker
research in `apps/tip_tracker/docs/research.md` and the category's common
searches; Play has no keyword field, so they are worked into the title,
short and full description.

Nothing here is saved in Play yet. Managed publishing is off, so saving the
listing sends it to Google review: it waits for Rajat's yes.

| Field | Value | Count |
|---|---|---|
| App name (30) | Tipwell: Tip & Shift Tracker | 28 |
| Short description (80) | Tip tracker for servers & bartenders: tip-out, cash vs card, real hourly pay. | 77 |
| Full description (4000) | below | 3170 |
| Category | Finance (Play) / Finance (App Store) | |
| Contains ads | Yes: one AdMob banner above the bottom tabs, never over the shift form | |
| In-app purchases | No for now: export and more jobs are free until billing is live | |
| Target search terms | tip tracker, tips tracker, server tips, bartender tips, tip out calculator, tip log, shift tracker, hourly rate, cash tips, waitress tips | |

App Store (later): subtitle "Tips, tip-out & hourly pay" (26/30), keywords "tips,tracker,server,bartender,tipout,waiter,waitress,shift,cash,hourly,income,log" (78/100).

## Graphics

- **App icon:** `icon-512.png` (512x512, the brand logo from `apps/tip_tracker/brand/logo.svg`)
- **Feature graphic:** `feature-graphic.png` (1024x500)
- **Phone screenshots:** `listing-screenshots/` (1080x1920, upload in this order).
  Captions are drawn into each picture in the house style: soft brand
  gradient, brand row, big headline, subhead, two tilted phones, the tip jar
  popping out on some.

1. `listing-screenshots/01.png`: **Know what you really made.** Cash, card and tip-out in. Take-home and hourly out.
2. `listing-screenshots/02.png`: **Log a shift in seconds.** Hours and tips are all it needs. Cash-only nights are fine.
3. `listing-screenshots/03.png`: **Tip-out, worked out.** Set your rule once: % of sales, % of tips or flat.
4. `listing-screenshots/04.png`: **See which nights pay best.** Tap any day or week for its take-home and hourly.
5. `listing-screenshots/05.png`: **Your tips, backed up.** Daily copies on your phone, one tap to Drive or email.
6. `listing-screenshots/06.png`: **Every job, one app.** Server, bartender or delivery. Each with its own pay period.
7. `listing-screenshots/07.png`: **Built for after close.** A dark mode that is easy on tired eyes.
8. `listing-screenshots/08.png`: **Private by default.** No account. Nothing uploaded. Your tips stay on your phone.

Raw app captures (no frame) are in `screenshots/`, taken during the passing
end-to-end run (121 of 121 checks), so every screen shows a working app with
real numbers.

## Full description

```text
Know what you really made tonight. Tipwell is a tip tracker for servers, bartenders and delivery drivers that turns cash tips, card tips and tip-out into your real take-home and your real hourly rate, shift by shift.

No account, no login, nothing to get locked out of. Your tips stay on your phone, and Tipwell backs them up every day so a lost phone or a bad update never costs you a year of history.

✨ HOW IT WORKS
1. Add your job: its name, hourly wage and tip-out rule
2. At the end of a shift, enter your hours and tips
3. See your take-home and hourly rate for the night, the week, the month and the year

⏱️ LOG A SHIFT IN SECONDS
• Only the hours are required, so cash-only, card-only and no-tip nights are fine
• Start and end times, or just the total hours
• Unpaid breaks come off automatically
• Shifts that run past midnight count as one shift
• Today and Yesterday buttons for the date
• Notes for each shift: section, drawer count, anything to remember

💸 TIP-OUT, WORKED OUT FOR YOU
• Set your rule once: a percent of sales, a percent of tips, or a flat amount
• Tipwell works out each night's tip-out to the bar, bussers or kitchen
• Change it for one night without changing your rule
• Add tip-in you got from coworkers
• Cash in pocket and tips kept are shown before you save

📊 YOUR NUMBERS, CLEARLY
• Take-home for the week, month, year or all time
• Your real hourly rate, wages included
• Tap any bar on the chart to see that day or week
• Find out which night of the week pays best
• Cash tips, card tips, tip-in, tip-out and wages, each on its own line
• A tax set-aside, so you know how much to put away
• Compare your hourly rate across jobs

👔 EVERY JOB, ONE APP
• Server, bartender, delivery or anything else
• Each job keeps its own wage and tip-out rule
• Each job can have its own pay period: weekly, every 2 weeks or twice a month
• See this pay period's total at a glance
• Archive an old job without losing its shifts

🛡️ NEVER LOSE A NIGHT
• A backup is made on your phone every day, and the last 14 are kept
• Save a backup to Google Drive, email or files with one tap
• See exactly what a backup holds before you restore it
• Every restore keeps a safety copy first, so you can undo it
• Moving to a new phone? Restore your backup on the first screen
• If something on the phone gets damaged, Tipwell helps you export what's readable and restore

📄 EXPORT FOR TAXES OR YOUR RECORDS
• A PDF report for any week, month or year
• A spreadsheet (CSV) for Excel, Google Sheets or your accountant

🔒 PRIVATE BY DEFAULT
• No account and no sign-up
• Your shifts are stored on your phone and never uploaded by us
• Backups and exports only go where you choose to send them
• One small banner ad, never over the shift form; nothing you enter is used for ads

❓ GOOD TO KNOW
• Works offline
• Pick your currency in Settings
• Light or dark theme, or follow your phone

Tipwell is free. Exports and more than one job are free for now too.

The tax set-aside is a rough guide, not tax advice. Check what you owe with a tax professional.

Questions or ideas? We read every message, and the best ideas end up in the app.

Devs at Widdle Studios
```

## What's new

```text
First release: log shifts in seconds, automatic tip-out, real hourly rate, pay periods per job, daily backups with undo, PDF and CSV reports, and a dark mode.
```
