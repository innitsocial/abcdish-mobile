# ABCDish Flutter Final Review Notes

## Included in this package

- Cleaned Flutter source project.
- Backend-aware API client with token refresh retry and request timeout handling.
- Auth flow support for email/password, email OTP, mobile OTP, forgot/reset password, JWT and refresh token storage.
- Splash/bootstrap screen for startup auth restoration.
- Backend-driven profile/session UI.
- Video access check before playback to support free/paid membership limits.
- Backend-ready shopping list integration with local fallback.
- Partner store / local store checkout options UI foundation.
- Improved readable dark-theme text styling.
- Removed duplicate Hero usage that caused multiple hero tag errors.
- API base URL now supports dart-define:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
flutter build ipa --release --dart-define=API_BASE_URL=https://your-api-domain.com
```

## Next before release

1. Run `flutter pub get`.
2. Run `dart format lib`.
3. Run `flutter analyze`.
4. Start backend and test login/register/profile/video/shopping flows.
5. Set production `API_BASE_URL` during release build.

## Multi-platform intent

The current Flutter app can evolve into:

- Mobile applications: iOS/Android
- Web application
- Public website
- Embedded/tablet/TV-style food video experience

Recommended future structure is feature-first modules under `lib/features` once the current backend integration is stable.
