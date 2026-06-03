# ABCDish Flutter Production-Facing Frontend

This package now includes frontend screens and service/provider layers for the backend platform modules implemented so far.

## Included frontend features

- Vertical food scrolling feed similar to short-form social/video apps
- Responsive navigation: bottom navigation for mobile, navigation rail for web/tablet/embedded style layouts
- Backend auth flow: email/password, OTP flows, refresh-token capable API client
- OAuth provider screen for Google, Apple, Facebook, Microsoft backend start endpoints
- Profile/session screen with membership, role, creator/admin affordances
- Creator media upload URL request screen
- Contest listing screen
- Contest entry submission screen
- Backend shopping list integration
- Partner store screen
- Shopping-list-to-partner-store checkout options foundation
- Video access service for free/paid viewing enforcement
- API base URL configured with Dart define: `--dart-define=API_BASE_URL=https://your-api-domain`

## Commands to run locally

```bash
flutter pub get
dart format lib
flutter analyze
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

## Production build examples

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://api.abcdish.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.abcdish.com
flutter build web --release --dart-define=API_BASE_URL=https://api.abcdish.com
```

## Important remaining items before store release

- Configure real OAuth redirect/token exchange with provider credentials
- Configure S3/CloudFront upload flow with native file picker
- Add real payment/IAP flow for membership
- Add moderation/reporting for contest uploads
- Add analytics/crash reporting
- Test on physical iOS and Android devices
