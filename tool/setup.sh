#!/usr/bin/env bash
# One-time setup: generates the android/ and ios/ folders around the existing
# lib/ code, then fixes the bits `flutter create` leaves out.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "Flutter isn't installed. See README.md → Setup."; exit 1; }

# Creates only missing files; lib/, pubspec.yaml and assets/ are kept.
flutter create --org com.hisabkhata --project-name hisabkhata --platforms android,ios .
# flutter create adds a sample widget test that doesn't match this app.
rm -f test/widget_test.dart

manifest=android/app/src/main/AndroidManifest.xml
# Release builds need the INTERNET permission (flutter create only adds it for debug).
if ! grep -q 'android.permission.INTERNET' "$manifest"; then
  sed -i.bak 's#<manifest xmlns:android="http://schemas.android.com/apk/res/android">#<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$manifest"
  rm -f "$manifest.bak"
fi
# App name under the icon.
sed -i.bak 's#android:label="hisabkhata"#android:label="HisabKhata"#' "$manifest" && rm -f "$manifest.bak"
plist=ios/Runner/Info.plist
if [ -f "$plist" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName HisabKhata" "$plist" 2>/dev/null || true
fi

flutter pub get
echo
echo "Done. Run the app with:  flutter run"
