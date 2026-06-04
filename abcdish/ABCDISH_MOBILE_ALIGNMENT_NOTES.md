# ABCDish Mobile Alignment Notes

This package has been aligned with the current ABCDish backend foundation.

## Included frontend coverage

- Public recipes/categories from backend
- Food feed screen with safe image-first scrolling cards
- Recipe detail screen with video loaded only after tapping Watch & Cook
- Auth/session startup with ProviderScope and splash screen
- Secure storage read protection for iOS
- Favourites
- Shopping list with local-first behaviour and best-effort backend sync
- Partner stores screen
- Contest listing and contest entry form foundation
- Creator upload draft screen
- OAuth provider discovery screen
- Profile links to creator tools, partner stores and OAuth providers

## iPhone stability choices

Video is deliberately not auto-initialised on app startup or feed scrolling. This avoids native iOS
`EXC_BAD_ACCESS` crashes from `video_player_avfoundation` while the app is being stabilised.

## Kept lock files

`pubspec.lock` and `ios/Podfile.lock` are kept because this is an application, not a package.
They help produce repeatable builds.

## Removed generated/cache files

The zip excludes:
- Pods
- build folders
- .dart_tool
- .symlinks
- macOS resource fork files
- DS_Store files
- local.properties
