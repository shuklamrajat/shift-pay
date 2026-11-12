# First-run tour: how it could fail

Written before the tour code. Each app's `integration_test/tour_e2e_test.dart`
checks these by number.

## When it shows
1. It starts over onboarding, or over an empty home screen with nothing to
   point at (no job or vehicle yet), so the spotlight lands on nothing.
2. It starts while Google's consent form is still coming, so the form covers
   it half way through (or the tour sits under the form).
3. Finishing or skipping isn't remembered, so it shows on every launch.
4. Closing the app in the middle marks it as seen, so the person never gets
   the rest of it (it should come back next launch).
5. "Take the tour" in Settings does nothing, or runs under the Settings page
   instead of over the home screen.

## What it shows
6. The spotlight misses the control it describes (wrong place or size).
7. The spotlight stays where a control used to be after the layout moves
   (a banner arriving or leaving).
8. A stop whose control isn't on screen (the add button lives on another tab)
   spotlights an empty patch instead of showing a plain card.
9. Back on the first stop or Next on the last one breaks; the step count is
   wrong.

## What it touches
10. A tap on the dimmed screen, or inside the spotlight, presses the control
    underneath and opens a form behind the tour.
11. An ad shows under the dim layer (AdMob does not allow content over ads),
    or a banner slides in mid-tour and moves things.
12. The banner never comes back after the tour ends.
