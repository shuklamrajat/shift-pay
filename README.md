# Wagebird

Hours and overtime pay tracker: shifts incl. split and overnight, clock in/out, daily and weekly overtime and double time, pay summaries, CSV/PDF timesheets.

Flutter app for Android and iOS. Everything stays on the device: no account,
no server. The free version covers the core; Pro is sold through the stores
(currently a local stand-in, see "Before the stores").

## Layout

| Path | What |
|------|------|
| apps/hours_tracker | The app |
| packages/app_core | Shared core: settings, onboarding, paywall and entitlements, ratings prompt, CSV/PDF export, theme |
| packages/e2e_driver | Helpers for the end-to-end test and store screenshots |
| store/ | Store listing, data safety answers, privacy policy, screenshots, icon, feature graphic |
| tool/ | Store screenshots, art and listing checks |
| .github/workflows | Android build on every push (see Android builds) |

`packages/` is a copy of the core shared with the other apps of the
portfolio. A fix there should be copied to the other app repos too.

## Set up

Needs Flutter 3.47 or newer (Dart 3.13).

```
flutter pub get
cd apps/hours_tracker && dart run build_runner build   # database code generation
flutter run                                     # on a phone or emulator
```

## Tests

End-to-end is the main test: it drives the real app on a real database through
a realistic scenario (two weeks of shifts, $1,425.00 total, 50 checks) and writes checkable artifacts.

```
apps/hours_tracker/tool/run_e2e.sh
# -> apps/hours_tracker/test-artifacts/e2e/: result.json (every check, expected vs seen),
#    the exported CSV and PDF, the PDF as text, checksums.txt
```

It runs on the Linux desktop target (needs clang, cmake, ninja, GTK 3,
xvfb, poppler-utils), with a fixed clock and TZ=America/New_York, so the
CSV checksum is the same on every run. The isolated logic scenarios run with
`cd apps/hours_tracker && TZ=America/New_York flutter test test/`; the failure modes
they cover are listed in `apps/hours_tracker/docs/`.

Store screenshots: `tool/store_shots.sh` reruns the end-to-end test at
1080x1920 and saves pictures to store/hours_tracker/screenshots/. It fails if any
check fails.

## Look and feel

The mascot and illustrations are drawn in code (`apps/hours_tracker/lib/src/ui/scenes.dart`)
and animated with the shared kit in `packages/app_core/lib/src/ui/` (scenes, charts
that draw in, count-up numbers, confetti on purchase). Endless loops stop and intros
jump to the end when the phone asks for reduced motion; the end-to-end test checks that.

## Store art

`tool/store_shots.sh` takes the phone screenshots from the end-to-end run,
`tool/make_store_art.py` makes the icon, framed listing screenshots and feature
graphic, and `tool/check_listings.py` checks Play's character limits. The
listing text is in `store/hours_tracker/listing.md`.

## Android builds

Every push to `main` runs `.github/workflows/android.yml` on GitHub Actions.

- **Without signing secrets:** it builds a debug APK. That proves the app
  compiles for Android, but it is not for Play.
- **With the four secrets below:** it builds a signed release bundle (`.aab`)
  ready to upload to Play Console. The run number becomes the version code, so
  each new bundle is newer than the last. The run fails if the bundle is signed
  with the debug key.

Download the file from the run's page (Actions tab, the run, then Artifacts).

### 1. Make an upload key, once, on your computer

`keytool` comes with Java; Android Studio includes it.

```
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

It asks for a password and a name. Keep `upload-keystore.jks` and the password
somewhere safe, outside this repo. Every update to the app on Play has to be
signed with the same upload key. Google keeps the real app signing key (Play App
Signing), so if the upload key is ever lost, Play support can reset it. The same
upload key can be used for all three apps.

Use a password without backslashes (`\`), because the build reads it from a
properties file.

### 2. Add four repository secrets

On GitHub: this repo, **Settings**, **Secrets and variables**, **Actions**,
**New repository secret**.

| Name | Value |
|------|-------|
| `ANDROID_KEYSTORE_BASE64` | The keystore file as base64 (commands below) |
| `ANDROID_KEYSTORE_PASSWORD` | The password you gave keytool |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | The same password (keytool uses one password for both unless you set two) |

To get the base64 text:

```
base64 -i upload-keystore.jks | pbcopy                 # macOS: copies it
base64 -w0 upload-keystore.jks                         # Linux
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard   # Windows PowerShell
```

### 3. Run it

Push to `main`, or open **Actions**, **Android build**, **Run workflow**.

To build signed on your own computer instead, create `apps/hours_tracker/android/key.properties`
(it is gitignored):

```
storeFile=/full/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

then run `flutter build appbundle --release` in `apps/hours_tracker`.

## Before the stores

See store/README.md. In short: the app id is `com.shuklamrajat.wagebird`; signed builds (see Android builds above; keep the upload key out of this repo),
RevenueCat in place of LocalEntitlementService, then Play internal testing.
