# Tipwell: data safety answers

For Google Play's Data safety form and Apple's App Privacy labels. Valid for
the current build: Tipwell has no analytics or network calls of its own; the
only outside service is the Google Mobile Ads SDK (one AdMob banner and
Google's consent form). Same answers as Wagebird, Wrenchnote and Housetally.
Mapping follows Google's own AdMob disclosure:
https://developers.google.com/admob/android/privacy/play-data-disclosure

## Google Play
- **Does your app collect or share any of the required user data types?** Yes, through the Google Mobile Ads SDK.
- **Is all user data encrypted in transit?** Yes (the SDK uses HTTPS).
- **Do you provide a way for users to request that their data be deleted?** The app's own data lives only on the device; deleting shifts or jobs, or uninstalling, removes it. Advertising data: the person can reset or delete their advertising ID in Android settings.
- **Data types, each collected and shared, processed ephemerally: no, optional: no:**
  - **Location > Approximate location** (from IP address): Advertising or marketing, Analytics, Fraud prevention, security and compliance.
  - **App activity > App interactions** (ad taps and views): Advertising or marketing, Analytics, Fraud prevention, security and compliance.
  - **App info and performance > Diagnostics:** Advertising or marketing, Analytics, Fraud prevention, security and compliance.
  - **Device or other IDs** (advertising ID, app set ID): Advertising or marketing, Analytics, Fraud prevention, security and compliance.
- **Financial info:** Not collected. Tips, wages and sales are typed in by the person and stay on the device; nothing is sent off it by the app.
- **Contains ads:** Yes. **Advertising ID:** Yes, used for advertising, analytics and fraud prevention (the Mobile Ads SDK adds `com.google.android.gms.permission.AD_ID` to the merged manifest).
- **Backups and exports:** backup files (JSON), CSV and PDF are created on the device and handed to the system share sheet at the person's request (Drive, email, files). Play treats user-initiated sharing like this as not "shared" by the developer.

## Apple App Privacy
Google's mapping for the Mobile Ads SDK: Device ID, Product interaction,
Advertising data, Coarse location, Crash and Performance data, used for
Third-party advertising and Analytics. Ads are not personalised unless the
person allows tracking (App Tracking Transparency, not requested by this
build), so "Used to track you" is No.

## Re-check when billing is added
While Pro is free there is no purchase code in the app. When RevenueCat or
Play Billing is added, Play's form will likely need **Purchase history**
marked as collected, for app functionality, not shared, not used for tracking.
