# Finding closed testers for Wagebird, Wrenchnote and Housetally

Researched 2026-11-12. Nothing here has been posted, joined or signed up for. Every post waits for
Rajat's okay and for the three closed testing links.

## 1. What Google actually asks (read on Google's own help page today)

Source: Play Console Help, "App testing requirements for new personal developer accounts"
(support.google.com/googleplay/android-developer/answer/14151465).

- Personal developer accounts created after 13 Nov 2023 need a closed test with **at least 12 testers
  opted in continuously for at least 14 days** before applying for production.
- Testers who opt in, test for fewer than 14 days and then opt out **don't count**. Opting out and back
  in breaks the run.
- The production application asks you to **summarise tester feedback and how you collected it**, and
  whether testers used all the app's features. Google lists "insufficient tester engagement" as a reason
  for rejection, so 12 people who install and never open the app is a real risk.
- Review of the application usually takes 7 days or less.

What that means for us:
- Aim for **18 to 20 per app**, not 12. Swap testers drop off (guides report 30 to 50%).
- **One Google Group for all three apps.** Set it as the tester list on all three closed tracks. A
  tester joins once, then taps the three opt-in links. Each app still needs its own 12, but one
  willing person can count for all three.
- Collect feedback in one place (a short Google Form or a reply email) so the production application
  has something real to summarise.
- Ship at least one small update during the 14 days, from tester feedback if possible.

## 2. Ranked places (best first)

Size and rules for Reddit are **unverified by me**: reddit.com is blocked from my tools, so the figures
come from directory sites and developer write-ups. Read each sub's pinned rules before the first post.

| # | Place | Type | Size and activity | Rules on tester asks | Account needs | Fit |
|---|---|---|---|---|---|---|
| 1 | r/AndroidClosedTesting | Reddit swap sub | Most-cited swap sub in every guide; posts every few minutes (seen via search results) | Exists for this. Guides say: test others first, post Google Group and opt-in link in its set format | Reddit account; karma/age limits not confirmed | All three |
| 2 | Testers Community app (free "Pack of 16") | Swap app on Play | Self-reports 50,000+ apps tested | Free tier: earn credits by testing 3 apps, join a pack of 16, open each of 15 apps daily for 16 days; 3 strikes and you're out. No Play reviews required | Android phone, app account | All three (one pack per app) |
| 3 | r/TestersCommunity | Reddit swap sub | Active; a dev.to author credits it with most of ~60 testers | Post description, test link and the feedback you want; testers join the community's group | Reddit account | All three |
| 4 | TheClosedTest | Swap app/site | Self-reports 15,000+ developers | Free. List app with Google Group and test link, swap tests, upload screenshot proofs. No Play reviews required | Android phone, app account | All three |
| 5 | r/alphaandbetausers | Reddit beta sub | About 52K members, ~30 posts a month (hiveindex) | Built for "people to use products and give feedback". Best chance of real feedback rather than swaps | Reddit account | Housetally, Wagebird |
| 6 | r/AndroidAppTesters | Reddit swap sub | Named by two write-ups; size not found | Swap posts | Reddit account | All three |
| 7 | r/betatests | Reddit beta sub | About 19K members, ~60 promo posts a month | Allowed, but strict post format; badly formatted posts are auto-removed | Reddit account | All three |
| 8 | Android Central forums, Apps subforum | Forum | Large, long-running Android forum | Rules read today: developers may post their own app, must say they're the developer, one thread per app, include a Play link and a screenshot, **no compensation for beta testers** | Forum account, 2 posts before links are allowed | All three, Wrenchnote best |
| 9 | Indie Hackers | Founder community | Several recent "need 12 testers" posts found | Show IH posts with a tester ask are common | Indie Hackers account | All three (one combined post) |
| 10 | r/20AndroidTesters | Reddit swap sub | Named by one write-up; size not found | Swap posts | Reddit account | All three |
| 11 | r/droidappshowcase | Reddit app showcase | Size not found | Post with Feedback flair | Reddit account | All three |

### Left out, and why
- **DevSwap** (Google Group "devswapgroup"): its 14-day cycle has members leave Play Store reviews
  "spread out to look like natural user activity". That's review manipulation under Play policy.
- **Paid tester services** (Testers Community Starter $15 / Pro $25, TestForPay, BetaCircle and
  similar): paying for testers was ruled out, and guides warn that emulator farms and fresh accounts
  are what Google's review looks for.
- **r/androiddev, r/Android, r/googleplay**: multiple guides say recruiting posts get removed there.
- **Fuelly forums**: run by a competing fuel-log app maker and the rules page wouldn't load. Skip.
- **Big audience subs** (nursing, retail, mechanics, homeowners, declutter): the sources I could read
  say most ban self-promotion and I couldn't read their rules myself. Only post in one after reading
  its rules and finding an explicit feedback or self-promo thread. Don't post the same text in many.
- **Discord and Telegram swap groups**: they exist (search Discord discovery for "closed testing"),
  but I couldn't verify any specific group. Worth a look by Rajat as extra, not a plan.
- Anything that offers money, gift cards or Pro in exchange for a review. Asking for honest private
  feedback is fine; asking for or rewarding Play reviews is not.

## 3. How swap places work (read before saying yes)

Swap subs and apps run on "I test yours, you test mine". For three apps that means Rajat (or a phone of
his) installs and opens 15 or so strangers' apps every day for about two weeks, and keeps them
installed until their tests end. Use a spare Android phone or a separate Google account if possible.
Swap testers are fast but give thin feedback; places 5, 7, 8 and 9 are where real feedback comes from.

## 4. What every tester needs to do (paste into every post)

1. Join the Google Group with the Google account your phone uses for Play: {GROUP_LINK}
2. Open the opt-in link for the app and tap "Become a tester": {OPTIN_LINK}
3. Install from Google Play (the opt-in page links to it).
4. Stay in the group and keep the app installed for 14 days. Open it a few times.

Join the group before tapping the opt-in link, or Play shows an error.

## 5. Draft posts

Placeholders: {GROUP_LINK}, {WAGEBIRD_OPTIN}, {WRENCHNOTE_OPTIN}, {HOUSETALLY_OPTIN},
{FEEDBACK_LINK}. Written in Rajat's voice. No dashes, no promises of payment or Pro.

### A. Swap subs: r/AndroidClosedTesting, r/TestersCommunity, r/AndroidAppTesters, r/20AndroidTesters

Same text works in all four; check each sub's required title format first. Post one app per post,
spaced out, not all three at once.

**Wagebird**
> Title: [Test for test] Wagebird: hours and overtime pay tracker
>
> Hi, I built Wagebird for shift workers who want to check their pay. Log shifts (overnight and split
> shifts too) and it works out regular, overtime and double time with your job's own rules. No account,
> nothing leaves your phone.
>
> 1. Join the group: {GROUP_LINK}
> 2. Opt in: {WAGEBIRD_OPTIN}
> 3. Install from Play and keep it 14 days
>
> I'll test yours back and keep it installed for your full 14 days. Drop your group and opt-in links
> below with a screenshot once you've joined mine.

**Wrenchnote**
> Title: [Test for test] Wrenchnote: car service and fuel log
>
> Hi, Wrenchnote logs fill-ups, works out real fuel economy (L/100 km or mpg) and reminds you about
> oil changes by date or distance. No account, data stays on your phone.
>
> 1. Join the group: {GROUP_LINK}
> 2. Opt in: {WRENCHNOTE_OPTIN}
> 3. Install from Play and keep it 14 days
>
> I'll test yours back and keep it for your full 14 days. Leave your links below.

**Housetally**
> Title: [Test for test] Housetally: home inventory with receipts and warranties
>
> Hi, Housetally is a photo inventory of your stuff, room by room, with receipts and warranty end
> dates, and a PDF report for an insurance claim. No account, no cloud.
>
> 1. Join the group: {GROUP_LINK}
> 2. Opt in: {HOUSETALLY_OPTIN}
> 3. Install from Play and keep it 14 days
>
> I'll test yours back for your full 14 days. Leave your links below.

### B. Feedback subs: r/alphaandbetausers and r/betatests

r/betatests auto-removes posts that miss its format, so copy its template from the pinned post and
fit this text into it.

**Wagebird**
> Title: Looking for Android testers: Wagebird, an hours and overtime pay checker for shift workers
>
> I work on small apps on the side and just finished Wagebird. It's for anyone paid by the hour who
> wants to check their pay stub: nurses, retail, warehouse, hospitality. You log shifts and it works
> out overtime with daily and weekly limits and your own multipliers.
>
> It's a free closed beta on Google Play. What I'd love feedback on: does the overtime match what your
> employer actually pays, and is logging a shift quick enough to do on a break?
>
> How to join (Google needs testers to stay in for 14 days):
> 1. Join the group: {GROUP_LINK}
> 2. Opt in: {WAGEBIRD_OPTIN}
> 3. Install and use it for a couple of weeks
>
> Feedback form: {FEEDBACK_LINK}. Thanks, I read everything.

**Wrenchnote**
> Title: Looking for Android testers: Wrenchnote, a car service and fuel log
>
> I built Wrenchnote to replace the spreadsheet I kept for my car. Log fill-ups, see real fuel economy,
> get reminded about oil changes and services by date or distance, and see what the car costs per km.
>
> Free closed beta on Google Play. I'd especially like to hear whether the economy numbers match what
> you expect after a few tanks, and what service items you'd want reminders for.
>
> How to join (Google needs testers to stay in for 14 days):
> 1. Join the group: {GROUP_LINK}
> 2. Opt in: {WRENCHNOTE_OPTIN}
> 3. Log a few fill-ups over two weeks
>
> Feedback form: {FEEDBACK_LINK}. Thanks!

**Housetally**
> Title: Looking for Android testers: Housetally, a home inventory for insurance and warranties
>
> If you had to claim on home insurance tomorrow, could you prove what you own? Housetally lets you
> photograph things room by room, keep receipts and warranty dates with each item, and export one PDF
> for a claim. Everything stays on your phone.
>
> Free closed beta on Google Play. I'd love to know how long it takes you to do one room, and whether
> the PDF report has what an insurer would ask for.
>
> How to join (Google needs testers to stay in for 14 days):
> 1. Join the group: {GROUP_LINK}
> 2. Opt in: {HOUSETALLY_OPTIN}
> 3. Add a room's worth of things over the two weeks
>
> Feedback form: {FEEDBACK_LINK}. Thanks!

### C. Android Central forums (one thread per app, in the matching Apps subforum)

Needs a Play link (the opt-in page is on Google Play, so it qualifies once the link exists), a
screenshot from `store/<app>/screenshots/`, and the developer disclosure. Two ordinary posts first,
because links are blocked before that. No mention of any reward.

**Wagebird**
> Title: [Beta] Wagebird: hours and overtime pay tracker (I'm the developer)
>
> Hi all, I'm the developer of Wagebird and I'm looking for a few Android testers before it goes
> public. It logs shifts and works out regular, overtime and double time using your job's daily and
> weekly limits. Overnight and split shifts work, and there's no account or cloud.
>
> To join the closed test: join {GROUP_LINK}, then opt in at {WAGEBIRD_OPTIN}, and keep it installed
> for 14 days (Google's rule for new apps). Screenshot attached. I'll keep this thread updated and
> answer everything here.

**Wrenchnote**
> Title: [Beta] Wrenchnote: car service and fuel log (I'm the developer)
>
> Hi all, I'm the developer of Wrenchnote and looking for Android testers. It logs fill-ups including
> partial tanks, shows real L/100 km or mpg, reminds you about services by date or distance and adds up
> what the car costs. No account, data stays on the phone.
>
> To join: {GROUP_LINK}, then opt in at {WRENCHNOTE_OPTIN}, and keep it 14 days. Screenshot attached.
> I'll post updates here and answer questions.

**Housetally**
> Title: [Beta] Housetally: home inventory with receipts and warranties (I'm the developer)
>
> Hi all, I'm the developer of Housetally and looking for Android testers. Photograph your things room
> by room, keep the receipt and warranty date with each, and export a PDF for an insurance claim.
> Nothing goes to the cloud.
>
> To join: {GROUP_LINK}, then opt in at {HOUSETALLY_OPTIN}, and keep it 14 days. Screenshot attached.
> I'll keep this thread updated.

### D. Indie Hackers (one combined post)

> Title: Show IH: I built three small Android apps and need testers to get past Google's 12 tester rule
>
> I'm building a set of simple, private, no-account utility apps. The first three are ready for
> closed testing on Google Play:
>
> - Wagebird: log shifts, see overtime pay worked out
> - Wrenchnote: fuel economy, service reminders and car costs
> - Housetally: home inventory with receipts, warranties and a claim PDF
>
> Google asks new developers for 12 testers who stay opted in for 14 days. Join one group
> ({GROUP_LINK}), then opt in to any you'd actually use:
> {WAGEBIRD_OPTIN} · {WRENCHNOTE_OPTIN} · {HOUSETALLY_OPTIN}
>
> If you're stuck on the same rule, post your links and I'll test yours back. Honest feedback welcome:
> {FEEDBACK_LINK}

### E. r/droidappshowcase (Feedback flair)

Use the section B text for each app, trimmed to the first two paragraphs plus the join steps.

### F. Swap apps: Testers Community and TheClosedTest (listing blurbs)

- **Wagebird:** Hours and overtime pay tracker for shift workers. Log a shift or two, set an overtime
  rule, check the weekly summary.
- **Wrenchnote:** Car fuel and service log. Add a car, log two fill-ups, set an oil change reminder.
- **Housetally:** Home inventory. Add three items with photos, add a warranty date, open the report.

The "what to try" lines matter: testers who use every feature help the production application.

## 6. Order of play once the links exist

1. Day 0: create the Google Group, set it on all three closed tracks, make the feedback form.
2. Day 0: post Wagebird in r/AndroidClosedTesting and r/TestersCommunity; list all three on one swap
   app.
3. Day 1 to 2: Wrenchnote and Housetally in the swap subs; section B posts; Indie Hackers.
4. Day 3: Android Central threads (after the two warm-up posts).
5. Every day: test others back, answer comments, update the tracker. Reminder email to the group on
   days 1, 5 and 10.
6. When a count passes 15, keep going anyway until day 14 is safely behind it.

## 7. Tracker

Play Console shows the opt-in count per app, not names. Record the count here each day.

| App | Place | Posted (date) | Link to post | Opt-ins after 2 days | Notes |
|---|---|---|---|---|---|
| Wagebird | r/AndroidClosedTesting | | | | |
| Wagebird | r/TestersCommunity | | | | |
| Wagebird | Testers Community app | | | | |
| Wagebird | TheClosedTest | | | | |
| Wagebird | r/alphaandbetausers | | | | |
| Wagebird | r/betatests | | | | |
| Wagebird | Android Central | | | | |
| Wrenchnote | r/AndroidClosedTesting | | | | |
| Wrenchnote | r/TestersCommunity | | | | |
| Wrenchnote | Testers Community app | | | | |
| Wrenchnote | TheClosedTest | | | | |
| Wrenchnote | r/betatests | | | | |
| Wrenchnote | Android Central | | | | |
| Housetally | r/AndroidClosedTesting | | | | |
| Housetally | r/TestersCommunity | | | | |
| Housetally | Testers Community app | | | | |
| Housetally | TheClosedTest | | | | |
| Housetally | r/alphaandbetausers | | | | |
| Housetally | r/betatests | | | | |
| Housetally | Android Central | | | | |
| All three | Indie Hackers | | | | |

Daily opt-in count (from Play Console):

| Date | Wagebird | Wrenchnote | Housetally | 14-day clock started |
|---|---|---|---|---|
| | | | | |

## Sources read
- Google Play Console Help, testing requirements (answer 14151465), read 2026-11-12
- Android Central "App and Developer Forum Rules & Guidelines", read 2026-11-12
- dev.to: "How to find 12 testers for your Android app" (ingrid_dev); "How I Found 12 Testers for Google
  Play Closed Testing, Twice" (metalhead_coder)
- The Hive Index pages for r/alphaandbetausers and r/betatests (member counts)
- Testers Community and TheClosedTest product pages (vendor claims, not verified)
- DevSwap Google Group about page (why it's excluded)
- appswap.pages.dev and testers.alphamf.com guides (Reddit rule notes; vendor sites)
