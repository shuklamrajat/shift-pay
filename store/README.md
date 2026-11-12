# Store listings

Drafts for Google Play first (internal testing track), App Store later.
App names are working names until Rajat picks the final ones; each listing
marks the name in one place so it is a one-line change.

| App | Working name | Free | Pro ($19.99/year with 7-day trial, or $39.99 once) |
|-----|--------------|------|------|
| hours_tracker | Shift Pay | one job, all overtime rules, pay summaries | more jobs, CSV and PDF timesheets |

Files per app: `listing.md` (title, short and full description, category,
tags, what's new), `data-safety.md` (answers for Play's Data safety form and
Apple's privacy labels), `screenshots/` (1080x1920, made by `tool/store_shots.sh`, which runs the full
end-to-end test at phone size and fails if any check fails), `icon-512.png`,
`feature-graphic.png`.
Shared: `privacy-policy.md` (needs a public URL before submission; GitHub
Pages from the repo works).

## Before the first upload (needs Rajat or his machine)

1. Final app names, then bundle ids (replace `com.placeholder.*` in
   android/app/build.gradle.kts and the iOS project).
2. Google Play: create the three apps in Play Console, fill the listing from
   these files, Data safety, content rating questionnaire, target audience
   (18+ not required; general audience, not aimed at children).
3. Build signed app bundles (.aab). This container can't download the Android
   SDK, so build on his computer or a build service such as Codemagic. Keep the
   upload key out of the repo.
4. RevenueCat: replace LocalEntitlementService with a RevenueCat-backed
   EntitlementService, create the products (pro_annual, pro_lifetime) in Play
   Console, then re-check data-safety.md (RevenueCat adds purchase data).
5. Upload to the internal testing track, add testers by email, install from
   the opt-in link. Google asks new personal developer accounts to run a closed
   test with testers for a period before production access; check the current
   requirement in Play Console when the account is set up.
6. Icons and feature graphics are placeholders made by `tool/make_store_art.py`
   (app colour plus a Material icon). It also writes the Android launcher and
   iOS app icons. Rerun after renaming; swap for designed art when there is budget.
7. Home Inventory's screenshots show test pictures (coloured squares) as item
   photos. Retake its third screenshot with real photos on a phone before
   production.
