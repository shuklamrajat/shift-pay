# Ads: how it can go wrong

Written before the ads code. Each line is a way the feature could fail a
person, AdMob's rules or the money it is meant to earn. The end-to-end test
`integration_test/ads_e2e_test.dart` in each app drives the real app through
these, with a fake ads platform in place of the Google SDK (the SDK has no
desktop build, so it cannot run in the Linux test runs).

## Consent (AdMob requires Google's consent form in the EEA and UK)

1. An ad is requested before consent has been gathered. AdMob treats this as
   a policy breach for EEA/UK users.
2. The consent form fails to load or is closed without an answer, and the
   app requests ads anyway (or crashes, or shows an empty slot forever).
   Once the person answers either way, Google's SDK allows requests and
   serves limited ads after a "no"; the app must go by the SDK's
   `canRequestAds`, not guess.
3. The consent check fails (offline, form error) and the app never shows an
   ad again, even on later launches. Google's guidance: carry on with the
   consent from the last session.
4. The consent form opens on every launch even after the person answered it.
   (The SDK decides; the app must not force it.)
5. There is no way to change the answer later. AdMob requires a "privacy
   options" entry point when the SDK says one is needed.
6. The privacy options row shows for people outside the EEA/UK where the SDK
   says it isn't needed (clutter, confusion).
7. The person changes their answer in privacy options and the app keeps
   showing (or keeps hiding) ads until a restart.

## Who sees ads

8. Someone who paid for Pro sees ads. Removing ads is part of what they paid for.
9. Nobody sees ads in the free-for-now build because "Pro is free" is read as
   "owns Pro". The plan: ads for everyone until paid Pro exists.
10. Ads show on desktop or in tests where there is no ad SDK (crash on a
    missing plugin).

## Placement and layout

11. The banner covers data entry, the floating add button or the bottom
    navigation, or appears on forms. Rule: one banner, docked above the
    bottom navigation on the main screen only; never on entry screens; no
    full-screen ads.
12. A failed ad load leaves an empty gap or a spinner that never ends.
13. The banner pops in and shoves the layout without warning. It should
    slide open once loaded, and stay still when the phone asks for reduced
    motion.
14. A banner is loaded again on every rebuild (wasted requests, flicker).
15. The banner is not disposed when the screen goes away (memory leak).

## IDs

16. A release build ships with Google's test ad IDs and earns nothing. The
    Android build warns while test IDs are in use.
17. A real ad unit is used during development (risks the AdMob account).
    Debug builds always use Google's test IDs.
</content>
</invoke>
