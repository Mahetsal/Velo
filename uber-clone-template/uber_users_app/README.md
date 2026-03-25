# Velo Rider App

Flutter rider app for requesting rides around Jordan.

## Prerequisites

- Flutter SDK `>=3.4.4`
- Firebase project configured (`google-services.json` / `GoogleService-Info.plist`)
- Google Maps API key set in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`

## Getting started

```bash
flutter pub get
flutter run
```

## Build variants

Override the API base URL at compile time:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

## Project structure

| Directory | Purpose |
|-----------|---------|
| `lib/api/` | Centralized `ApiClient` — single HTTP + auth layer |
| `lib/appInfo/` | `AppInfoClass` (locale/theme) and `AuthenticationProvider` |
| `lib/authentication/` | Login, OTP, registration screens |
| `lib/pages/` | Top-level screens (home, trips, wallet, account, etc.) |
| `lib/widgets/` | Reusable UI components and ride sheets |
| `lib/methods/` | Helpers — fare calculation, push notifications |
| `lib/models/` | Data models (user, address, direction, prediction) |
| `lib/global/` | Minimal global state (being migrated into providers) |
| `lib/l10n/` | EN/AR localization ARB files |
| `lib/theme/` | Velo Material 3 theme |

## Localization

Supported: English (`en`), Arabic (`ar`). Add keys to `lib/l10n/app_en.arb` / `app_ar.arb`, then run:

```bash
flutter gen-l10n
```

## Production checklist

1. **Firebase** — Run `flutterfire configure` to generate your own `firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist`. The checked-in files use the public FlutterFire e2e test project as a placeholder.
2. **Google Maps API key** — The key is injected at build time via `MAPS_API_KEY`:
   - Android: reads `${MAPS_API_KEY}` from `AndroidManifest.xml` (set via `local.properties` or Gradle `-P` flag).
   - iOS: reads `$(MAPS_API_KEY)` from `Info.plist` (set via Xcode build settings or `xcconfig`).
   - Restrict the key in the Google Cloud Console to your app's package name (`com.velo.rider`) and iOS bundle ID. Enable only the Maps SDK and Places API.
3. **API base URL** — Pass `--dart-define=API_BASE_URL=https://your-api.example.com` at build time. The default targets a staging endpoint.
4. **App signing** — Configure Android keystore and iOS distribution certificate before release builds.
5. **Store assets** — App icons are already generated at all required densities for Android (`mipmap-*`) and iOS (`Assets.xcassets/AppIcon.appiconset`).
