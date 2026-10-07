# HisabKhata — mobile app

A Flutter app for **HisabKhata**: the mess bazar, meal and bill tracker. It talks
to the hosted API at `https://messhisabkhata.vercel.app/api/v1` and follows the web
app's look: forest green with amber, light and dark themes, **Bangla by default**
with an English toggle.

## What's in it

| Screen | What you can do |
|---|---|
| **Sign in** | Username or email + password (show/hide), language and theme toggles |
| **Monthly → Expense** | Total bazar, total meals and meal rate; bazar per person (tap to see entries); add, edit or delete a bazar with items (catalog suggestions in English or Bangla, new names join the catalog) or just a total |
| **Monthly → Meal** | Day slider (opens on today) with every member's meals: −/+ or type a value. It saves as you go. The month sheet is split into 1–10 / 11–20 / 21–end so it fits a phone. Tap a total to type a monthly total. |
| **Monthly → Rent** | The settlement: last month's meal cost plus this month's own and shared bills, minus bazar done. Each member has a full bill breakdown and a balance (pays / gets back). Chips leave columns out of the total. Shared bills: add (presets), edit, delete, or copy from last month. |
| **Members** | Add, edit (Bangla name, joined/left dates), delete (records are kept as "Deleted member"); set each member's monthly bills from a month onward; bills for everyone at once |
| **Bills** | Bill types (add, rename, delete when unused); who pays what in a month |
| **Food items** | Search, add (English + Bangla name), rename, delete when unused |
| **Settings** | Mess name (shown next to the logo), language, theme, profile, password change, sign out (this device / everywhere) |

Viewers (read-only members of a mess) see everything without edit controls. Accounts
with no mess, such as the super admin, get a note to use the web admin panel; the
admin tools have no API.

## Setup

1. Install Flutter 3.32 or newer: <https://docs.flutter.dev/get-started/install/macos>
   (or `brew install --cask flutter`). Then run `flutter doctor` and follow what it
   says for Android Studio and/or Xcode.
2. In this folder, run the one-time setup. It creates the `android/` and `ios/`
   folders, adds the Android INTERNET permission and the app name, and gets the packages:

   ```bash
   ./tool/setup.sh
   ```

   (Manual equivalent: `flutter create --org com.hisabkhata --project-name hisabkhata --platforms android,ios .`
   then `flutter pub get`. Add `<uses-permission android:name="android.permission.INTERNET"/>`
   to `android/app/src/main/AndroidManifest.xml`, or release builds can't reach the API.)
3. Start an emulator or plug in a phone, then run:

   ```bash
   flutter run
   ```

Checks: `flutter analyze` and `flutter test`.

### Pointing at another server

```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:3012/api/v1   # local dev server from the Android emulator
```

### Release builds

```bash
flutter build apk --release        # Android APK  → build/app/outputs/flutter-apk/
flutter build appbundle --release  # Play Store
flutter build ipa                  # iOS (needs Xcode signing)
```

## Builds on GitHub (iPhone + Android, no Mac setup needed)

`.github/workflows/build.yml` builds both apps on every push to `main`, and whenever you
press **Actions → Build apps → Run workflow**:

- **iPhone:** `HisabKhata-unsigned.ipa`, built on a GitHub macOS machine without signing
- **Android:** `HisabKhata.apk`

Open the finished run and download them under **Artifacts**. Pushing a tag
(`git tag v1.0.0 && git push --tags`) also attaches both files to a GitHub Release.

### Installing the .ipa on an iPhone

An unsigned .ipa has to be signed with your Apple ID when you install it:

1. Install **Sideloadly** (https://sideloadly.io) on a Mac or Windows PC. AltStore also works.
2. Connect the iPhone and drag `HisabKhata-unsigned.ipa` into Sideloadly.
3. Enter your Apple ID and click **Start**.
4. On the iPhone, turn on **Settings → Privacy & Security → Developer Mode**.
   Then trust your Apple ID under **Settings → General → VPN & Device Management**.

With a free Apple ID the app works for 7 days; install it again to renew it. A paid
Apple Developer account ($99/year) would let the workflow sign the app and send it
to TestFlight.

Note: on a private repo, macOS build minutes count 10× against GitHub's free
monthly minutes, so one iPhone build of about 10 minutes uses about 100 of them.

## Code map

```
lib/
  main.dart              app, theme mode, which screen (sign in / no mess / app)
  config.dart            API base URL (overridable with --dart-define)
  theme.dart             colours from the web's globals.css, light + dark
  format.dart            ৳ amounts, 0–9 digits, Bangla/English month names, Dhaka dates
  models.dart            JSON → classes; month stats (meals, typed totals, rate)
  api/api.dart           HTTP client: Bearer token, error shape, 401 → sign out
  state/app_state.dart   session, mess + role, language, theme; `changed()` reloads screens
  i18n/strings.dart      every UI text in Bangla and English
  widgets/common.dart    header pieces, cards, stat tiles, month switcher, loader, dialogs
  screens/               login, home shell (bottom menu), monthly tabs, members, bills, items, settings
assets/brand/            logo (light/dark) and mark from the web app
```

Notes:
- The token is kept in the iOS Keychain / Android Keystore (`flutter_secure_storage`).
  Language and theme are kept in `shared_preferences`.
- The app uses the account's first mess. The API picks it when no `X-Mess-Id` is sent.
- The Expense and Meal tabs work out the month's own bazar, meals and rate from
  `GET /months/:month`, the same way the web does. The Rent tab uses that month's
  `summary`.
