# ABCDish iPhone Device Testing Notes

## What was fixed

- Default API URL now points to the Railway HTTPS backend.
- Removed production `print` calls.
- Added safer auth state clearing.
- Video player no longer initialises in `MealDetailsScreen.initState()`.
- Video is initialised only after the user taps **Watch & Cook**.
- `MealVideoPlayer` was also made lazy to avoid AVFoundation crashes on second app launch.
- iOS `Podfile` now explicitly sets `platform :ios, '13.0'`.
- `flutter_secure_storage` was pinned to a stable 9.x line to reduce iOS native plugin instability.

## Recommended local commands

```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData
flutter pub get
cd ios
pod install
cd ..
flutter run --dart-define=API_BASE_URL=https://abcdish-backend-production.up.railway.app
```

## If the app still crashes on second launch

Run:

```bash
flutter uninstall
flutter clean
flutter pub get
flutter run --dart-define=API_BASE_URL=https://abcdish-backend-production.up.railway.app
```

This clears old secure storage and old app state from the iPhone.
