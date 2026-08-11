# iOS / Xcode setup

The iOS project is configured for iOS 14.0+ and Flutter 3.41.0+.

## Requirements

- macOS
- Xcode
- Flutter 3.41.0 or newer
- CocoaPods
- An Apple ID / Apple Development Team for installing on a physical iPhone

## First-time setup

Run from Terminal:

```bash
git clone https://github.com/ibrodevs/Baby-locator-lite.git
cd Baby-locator-lite

flutter clean
flutter pub get

cd ios
pod install --repo-update
cd ..

open ios/Runner.xcworkspace
```

Do not open `ios/Runner.xcodeproj` directly. Flutter plugins are integrated through CocoaPods, so use `Runner.xcworkspace`.

## Signing in Xcode

After opening the workspace:

1. Select the `Runner` target.
2. Open **Signing & Capabilities**.
3. Keep **Automatically manage signing** enabled.
4. Select your own Apple Development **Team**.
5. Connect the iPhone, select it as the run destination, and press **Run**.

The Podfile automatically synchronizes the Runner/RunnerTests bundle identifiers with the `BUNDLE_ID` from `ios/Runner/GoogleService-Info.plist`, so Firebase and Xcode use the same application identifier. It also removes the repository author's hard-coded Development Team before Xcode is opened.

## Firebase push notifications

The app can be built and installed without configuring APNs, but Firebase Cloud Messaging on a real iPhone requires the Apple Push Notifications capability and an APNs authentication key/certificate configured for the Firebase project. This depends on the Apple Developer account used for the app and cannot be shared through the source repository alone.

## If CocoaPods reports an out-of-sync sandbox

Run:

```bash
flutter pub get
cd ios
rm -rf Pods
pod install --repo-update
cd ..
```

Then reopen `ios/Runner.xcworkspace`.
