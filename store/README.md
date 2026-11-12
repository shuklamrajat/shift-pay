# Store listings

Google Play first (closed testing track), App Store later. Final names
chosen by Rajat on 12 Nov 2026. App and bundle ids use one scheme on Android,
iOS and Linux: `com.shuklamrajat.<brand>`.

| App | Name and id | Free | Pro ($19.99/year with 7-day trial, or $39.99 once) |
|-----|--------------|------|------|
| hours_tracker | Wagebird: Hours & Pay Tracker, `com.shuklamrajat.wagebird` | one job, all overtime rules, pay summaries | more jobs, CSV and PDF timesheets |
| fuel_log | Wrenchnote: Car & Fuel Log, `com.shuklamrajat.wrenchnote` | one vehicle, fill-ups, economy, reminders, costs | more vehicles, CSV and PDF history |
| home_inventory | Housetally: Home Inventory, `com.shuklamrajat.housetally` | 25 items with photos, receipts, warranties | unlimited items, insurance PDF and CSV |

Files per app:
- `listing.md`: title, short and full description (checked against Play's
  limits by `tool/check_listings.py`), category, search terms, what's new,
  screenshot order and captions.
- `listing-screenshots/`: the framed 1080x1920 pictures to upload, in order.
- `screenshots/`: raw app captures from `tool/store_shots.sh`, which runs the
  full end-to-end test at phone size and fails if any check fails.
- `icon-512.png`, `feature-graphic.png`: from `tool/make_store_art.py`, which
  renders each app's own mascot with Flutter and frames the screenshots.
- `data-safety.md`: answers for Play's Data safety form and Apple's labels.

Shared: `privacy-policy.md` (needs a public URL before submission; GitHub
Pages from the repo works), `naming.md` (name research), `testers.md`.

To rebuild all store art: `tool/store_shots.sh && tool/make_store_art.py && tool/check_listings.py`.

## Before the first upload (needs Rajat)

1. Search each name once more in the Play Store and App Store boxes and on
   USPTO/WIPO (see naming.md).
2. Google Play: create the three apps in Play Console, fill the listing from
   these files, Data safety, content rating questionnaire, target audience
   (18+ not required; general audience, not aimed at children).
3. Build signed app bundles (.aab). Each app repo has a GitHub Actions
   workflow that builds one on every push to main once the upload key is added
   as repository secrets (see that repo's README, "Android builds"). Keep the
   upload key out of the repo.
4. RevenueCat: replace LocalEntitlementService with a RevenueCat-backed
   EntitlementService, create the products (pro_annual, pro_lifetime) in Play
   Console, then re-check data-safety.md (RevenueCat adds purchase data).
5. Upload to the internal testing track, add testers by email, install from
   the opt-in link. Google asks new personal developer accounts to run a closed
   test with testers for a period before production access; check the current
   requirement in Play Console when the account is set up.
6. Icons are drawn from each app's mascot by `tool/make_store_art.py`, which
   also writes the Android launcher and iOS app icons. Android adaptive
   (foreground/background) icons are not made yet; the legacy icons work.
7. Housetally's screenshots show test pictures (coloured squares) as item
   photos. Retake the item screenshot (listing slide 2) with real photos on a phone before
   production.
